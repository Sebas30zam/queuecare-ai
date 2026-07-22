class PublicScreensController < ApplicationController
  ACTIVE_TICKETS_LIMIT = 10
  RECENT_TICKETS_LIMIT = 6

  def index
    render inertia: "public-screen/index", props: {
      active_tickets: serialize_tickets(
        Ticket.active_for_public_screen.limit(ACTIVE_TICKETS_LIMIT)
      ),
      recently_called_tickets: serialize_tickets(
        Ticket.recently_called_for_public_screen.limit(RECENT_TICKETS_LIMIT)
      ),
      generated_at: Time.current.iso8601
    }
  end

  private

  def serialize_tickets(tickets)
    tickets.map do |ticket|
      {
        id: ticket.id,
        ticket_number: ticket.ticket_number,
        status: ticket.status,
        called_at: ticket.called_at.iso8601,
        queue_service: {
          id: ticket.queue_service.id,
          name: ticket.queue_service.name,
          code: ticket.queue_service.code
        },
        service_window: serialize_service_window(ticket.service_window),
        assigned_agent: serialize_assigned_agent(ticket.assigned_agent)
      }
    end
  end

  def serialize_service_window(service_window)
    return unless service_window

    {
      id: service_window.id,
      name: service_window.name,
      code: service_window.code
    }
  end

  def serialize_assigned_agent(assigned_agent)
    return unless assigned_agent

    {
      id: assigned_agent.id,
      name: assigned_agent.name
    }
  end
end
