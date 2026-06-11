module Tickets
  class MarkNoShowService
    ALLOWED_ROLES = %w[agent admin].freeze
    NO_SHOW_WAIT_SECONDS = 15

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
          "Current user is not authorized to mark tickets as no-show"
        )
      end

      unless ticket&.persisted?
        return failure("Ticket is required")
      end

      ticket.with_lock do
        unless ticket.status == "called"
          return failure("Ticket must be called before it can be marked as no-show")
        end

        unless ticket.assigned_agent == current_user
          return failure("Ticket is assigned to another agent")
        end

        return failure("Service window is required") if ticket.service_window.blank?
        return failure("Called at is required") if ticket.called_at.blank?

        unless no_show_wait_time_elapsed?
          return failure(
            "Ticket can only be marked as no-show 15 seconds after it was called"
          )
        end

        ticket.update!(
          status: "no_show",
          no_show_at: Time.current
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

    def no_show_wait_time_elapsed?
      ticket.called_at <= NO_SHOW_WAIT_SECONDS.seconds.ago
    end

    def failure(message)
      Result.new(ticket: nil, errors: [message])
    end
  end
end
