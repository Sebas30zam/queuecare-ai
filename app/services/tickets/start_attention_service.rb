module Tickets
  class StartAttentionService
    ALLOWED_ROLES = %w[agent admin].freeze

    Result = Struct.new(:ticket, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def initialize(current_user:, ticket:)
      @current_user = current_user
      @ticket = ticket
    end

    def call
      return failure("Current user is required") if current_user.blank?

      unless ALLOWED_ROLES.include?(current_user.role&.name)
        return failure(
          "Current user is not authorized to start attention"
        )
      end

      unless ticket&.persisted?
        return failure("Ticket is required")
      end

      ticket.with_lock do
        return failure("Ticket must be called before attention can start") unless ticket.status == "called"

        unless ticket.assigned_agent == current_user
          return failure("Ticket is assigned to another agent")
        end

        return failure("Service window is required") if ticket.service_window.blank?
        return failure("Called at is required") if ticket.called_at.blank?

        ticket.update!(
          status: "in_attention",
          started_at: Time.current
        )
      end

      Result.new(ticket: ticket, errors: [])
    rescue ActiveRecord::RecordInvalid => error
      Result.new(
        ticket: error.record.is_a?(Ticket) ? error.record : nil,
        errors: error.record.errors.full_messages
      )
    end

    private

    attr_reader :current_user, :ticket

    def failure(message)
      Result.new(ticket: nil, errors: [message])
    end
  end
end
