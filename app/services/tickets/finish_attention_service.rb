module Tickets
  class FinishAttentionService
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
          "Current user is not authorized to finish attention"
        )
      end

      unless ticket&.persisted?
        return failure("Ticket is required")
      end

      ticket.with_lock do
        unless ticket.status == "in_attention"
          return failure(
            "Ticket must be in attention before attention can finish"
          )
        end

        unless ticket.assigned_agent == current_user
          return failure("Ticket is assigned to another agent")
        end

        return failure("Started at is required") if ticket.started_at.blank?

        ticket.update!(
          status: "attended",
          finished_at: Time.current
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
      Result.new(ticket: nil, errors: [ message ])
    end
  end
end
