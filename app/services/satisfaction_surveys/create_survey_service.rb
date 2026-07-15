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
      unless ticket&.persisted?
        return failure("Ticket is required")
      end

      survey = nil

      ticket.with_lock do
        unless ticket.status == "attended"
          return failure("Ticket must be attended before submitting a survey")
        end

        if ticket.finished_at.blank?
          return failure("Finished at is required")
        end

        if SatisfactionSurvey.exists?(ticket_id: ticket.id)
          return failure("Ticket already has a satisfaction survey")
        end

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
