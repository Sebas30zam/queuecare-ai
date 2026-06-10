module Tickets
  class CreateTicketService
    Result = Struct.new(:ticket, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def initialize(current_user:, params:)
      @current_user = current_user
      @params = params.to_h.symbolize_keys
    end

    def call
      intake_source = params[:intake_source].to_s

      unless Ticket::INTAKE_SOURCES.include?(intake_source)
        return failure("Intake source is invalid")
      end

      if intake_source == "assisted" && current_user.blank?
        return failure("Current user is required for assisted intake")
      end

      queue_service = QueueService.find_by(
        id: params[:queue_service_id],
        active: true
      )

      return failure("Queue service is unavailable") unless queue_service

      assistance_type = params[:assistance_type].to_s.presence

      if assistance_type.present? &&
         !Ticket::ASSISTANCE_TYPES.include?(assistance_type)
        return failure("Assistance type is invalid")
      end

      priority = assistance_type || "normal"
      priority_weight = Ticket::PRIORITY_WEIGHTS.fetch(priority)

      ticket = create_ticket(
        queue_service: queue_service,
        intake_source: intake_source,
        assistance_type: assistance_type,
        priority: priority,
        priority_weight: priority_weight
      )

      Result.new(ticket: ticket, errors: [])
    rescue ActiveRecord::RecordInvalid => error
      Result.new(
        ticket: error.record.is_a?(Ticket) ? error.record : nil,
        errors: error.record.errors.full_messages
      )
    rescue ActiveRecord::RecordNotUnique
      failure("The ticket number could not be generated. Please try again.")
    end

    private

    attr_reader :current_user, :params

    def create_ticket(
      queue_service:,
      intake_source:,
      assistance_type:,
      priority:,
      priority_weight:
    )
      ticket = nil

      ActiveRecord::Base.transaction do
        sequence_date = Date.current

        queue_service.with_lock do
          daily_sequence = DailySequence.find_or_create_by!(
            queue_service: queue_service,
            sequence_date: sequence_date
          ) do |sequence|
            sequence.current_number = 0
          end

          daily_sequence.with_lock do
            next_number = daily_sequence.current_number + 1

            ticket = Ticket.create!(
              queue_service: queue_service,
              created_by: intake_source == "assisted" ? current_user : nil,
              ticket_number: build_ticket_number(queue_service, next_number),
              sequence_date: sequence_date,
              daily_sequence: next_number,
              priority: priority,
              priority_weight: priority_weight,
              status: "pending",
              intake_source: intake_source,
              assistance_type: assistance_type
            )

            daily_sequence.update!(current_number: next_number)
          end
        end
      end

      ticket
    end

    def build_ticket_number(queue_service, number)
      "#{queue_service.code}-#{number.to_s.rjust(3, "0")}"
    end

    def failure(message)
      Result.new(ticket: nil, errors: [message])
    end
  end
end
