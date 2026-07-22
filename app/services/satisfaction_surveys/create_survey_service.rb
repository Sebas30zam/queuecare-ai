module SatisfactionSurveys
  class CreateSurveyService
    Result = Struct.new(:survey, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def initialize(ticket:, rating:, comment:)
      @ticket = ticket
      @rating = rating
      @comment = comment
    end

    def call
      return failure("Ticket is required") unless ticket&.persisted?

      survey = nil

      ticket.with_lock do
        return failure("Ticket must be attended before submitting a survey") unless ticket.status == Ticket::ATTENDED_STATUS
        return failure("Finished at is required") if ticket.finished_at.blank?
        return failure("Ticket already has a satisfaction survey") if SatisfactionSurvey.exists?(ticket_id: ticket.id)

        survey = SatisfactionSurvey.create!(
          ticket: ticket,
          rating: rating,
          comment: comment,
          submitted_at: Time.current
        )
      end

      Result.new(survey: survey, errors: [])
    rescue ActiveRecord::RecordInvalid => error
      Result.new(
        survey: error.record.is_a?(SatisfactionSurvey) ? error.record : nil,
        errors: error.record.errors.full_messages
      )
    rescue ActiveRecord::RecordNotUnique
      failure("Ticket already has a satisfaction survey")
    end

    private

    attr_reader :ticket, :rating, :comment

    def failure(message)
      Result.new(survey: nil, errors: [ message ])
    end
  end
end
