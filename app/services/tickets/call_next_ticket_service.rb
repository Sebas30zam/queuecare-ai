module Tickets
  class CallNextTicketService
    ALLOWED_ROLES = %w[agent admin].freeze

    Result = Struct.new(:ticket, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def initialize(current_user:, service_window:)
      @current_user = current_user
      @service_window = service_window
    end

    def call
      return failure("Current user is required") if current_user.blank?

      unless ALLOWED_ROLES.include?(current_user.role&.name)
        return failure("Current user is not authorized to call tickets")
      end

      unless service_window&.persisted?
        return failure("Service window is required")
      end

      return failure("Service window is inactive") unless service_window.active?

      unless service_window.queue_service&.active?
        return failure("Queue service is inactive")
      end

      ticket = nil

      current_user.with_lock do
        service_window.with_lock do
          if active_ticket?
            return failure("The agent already has an active ticket")
          end

          if service_window_active_ticket?
            return failure("The service window already has an active ticket")
          end

          ticket = call_next_ticket
        end
      end

      unless ticket
        return failure("No pending tickets are available for this service")
      end

      Result.new(ticket: ticket, errors: [])
    rescue ActiveRecord::RecordInvalid => error
      Result.new(
        ticket: error.record.is_a?(Ticket) ? error.record : nil,
        errors: error.record.errors.full_messages
      )
    end

    private

    attr_reader :current_user, :service_window

    def active_ticket?
      Ticket.exists?(
        assigned_agent: current_user,
        status: %w[called in_attention]
      )
    end

    def service_window_active_ticket?
      Ticket.exists?(
        service_window: service_window,
        status: %w[called in_attention]
      )
    end

    def call_next_ticket
      ticket = nil

      ActiveRecord::Base.transaction do
        ticket = Ticket
                 .where(
                   queue_service_id: service_window.queue_service_id,
                   status: "pending"
                 )
                 .order(:priority_weight, :created_at, :id)
                 .lock("FOR UPDATE SKIP LOCKED")
                 .first

        if ticket
          ticket.update!(
            service_window: service_window,
            assigned_agent: current_user,
            status: "called",
            called_at: Time.current
          )
        end
      end

      ticket
    end

    def failure(message)
      Result.new(ticket: nil, errors: [message])
    end
  end
end
