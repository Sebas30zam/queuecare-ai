class AgentQueuesController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:agent, :admin) }

  def index
    service_windows = available_service_windows
    selected_service_window = selected_service_window_from(service_windows)

    render inertia: "agent-queue/index", props: {
      service_windows: serialize_service_windows(service_windows),
      selected_service_window: serialize_service_window(
        selected_service_window
      ),
      pending_tickets: serialize_pending_tickets(
        selected_service_window
      ),
      current_called_ticket: serialize_current_called_ticket(
        selected_service_window
      )
    }
  end

  def call_next
    service_window = ServiceWindow
                     .includes(:queue_service)
                     .find_by(id: params[:service_window_id])

    result = Tickets::CallNextTicketService.new(
      current_user: current_user,
      service_window: service_window
    ).call

    if result.success?
      redirect_to agent_queue_path(
        service_window_id: result.ticket.service_window_id
      ),
                  notice: "Ticket #{result.ticket.ticket_number} called successfully."
    else
      redirect_to agent_queue_path(
        service_window_id: params[:service_window_id]
      ),
                  alert: result.errors.to_sentence
    end
  end

  private

  def available_service_windows
    ServiceWindow
      .includes(:queue_service)
      .where(active: true, queue_services: { active: true })
      .order(:code)
  end

  def selected_service_window_from(service_windows)
    return service_windows.first if params[:service_window_id].blank?

    service_windows.find_by(id: params[:service_window_id])
  end

  def pending_tickets_for(service_window)
    return Ticket.none unless service_window

    Ticket
      .where(
        queue_service_id: service_window.queue_service_id,
        status: "pending"
      )
      .order(:priority_weight, :created_at, :id)
  end

  def current_called_ticket_for(service_window)
    return unless service_window

    Ticket
      .includes(:queue_service, :service_window, :assigned_agent)
      .where(
        service_window: service_window,
        status: "called"
      )
      .order(called_at: :desc, id: :desc)
      .first
  end

  def serialize_service_windows(service_windows)
    service_windows.map do |service_window|
      serialize_service_window(service_window)
    end
  end

  def serialize_service_window(service_window)
    return unless service_window

    {
      id: service_window.id,
      name: service_window.name,
      code: service_window.code,
      queue_service: {
        id: service_window.queue_service.id,
        name: service_window.queue_service.name,
        code: service_window.queue_service.code
      }
    }
  end

  def serialize_pending_tickets(service_window)
    pending_tickets_for(service_window).map do |ticket|
      {
        id: ticket.id,
        ticket_number: ticket.ticket_number,
        priority: ticket.priority,
        assistance_type: ticket.assistance_type,
        intake_source: ticket.intake_source,
        created_at: ticket.created_at.iso8601
      }
    end
  end

  def serialize_current_called_ticket(service_window)
    ticket = current_called_ticket_for(service_window)

    return unless ticket

    {
      id: ticket.id,
      ticket_number: ticket.ticket_number,
      priority: ticket.priority,
      assistance_type: ticket.assistance_type,
      intake_source: ticket.intake_source,
      called_at: ticket.called_at&.iso8601,
      assigned_agent: {
        id: ticket.assigned_agent.id,
        name: ticket.assigned_agent.name
      },
      service_window: {
        id: ticket.service_window.id,
        name: ticket.service_window.name,
        code: ticket.service_window.code
      },
      queue_service: {
        id: ticket.queue_service.id,
        name: ticket.queue_service.name,
        code: ticket.queue_service.code
      }
    }
  end
end
