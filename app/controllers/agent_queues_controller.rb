class AgentQueuesController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:agent, :admin) }

  def index
    service_windows = available_service_windows
    selected_service_window = selected_service_window_from(service_windows)

    agent_active_ticket = active_ticket_for_current_user
    selected_service_window_busy = service_window_busy?(
      selected_service_window
    )

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
      ),
      current_in_attention_ticket: serialize_current_in_attention_ticket(
        selected_service_window
      ),
      agent_active_ticket: serialize_agent_active_ticket(
        agent_active_ticket
      ),
      selected_service_window_busy: selected_service_window_busy
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

  def start_attention
    ticket = Ticket.find_by(id: params[:id])

    result = Tickets::StartAttentionService.new(
      current_user: current_user,
      ticket: ticket
    ).call

    if result.success?
      redirect_to agent_queue_path(
        service_window_id: result.ticket.service_window_id
      ),
                  notice: "Ticket #{result.ticket.ticket_number} attention started successfully."
    else
      redirect_to agent_queue_path(
        service_window_id: ticket&.service_window_id ||
          params[:service_window_id]
      ),
                  alert: result.errors.to_sentence
    end
  end

  def finish_attention
    ticket = Ticket.find_by(id: params[:id])

    result = Tickets::FinishAttentionService.new(
      current_user: current_user,
      ticket: ticket
    ).call

    if result.success?
      redirect_to agent_queue_path(
        service_window_id: result.ticket.service_window_id
      ),
                  notice: "Ticket #{result.ticket.ticket_number} attention finished successfully."
    else
      redirect_to agent_queue_path(
        service_window_id: ticket&.service_window_id ||
          params[:service_window_id]
      ),
                  alert: result.errors.to_sentence
    end
  end

  def mark_no_show
    ticket = Ticket.find_by(id: params[:id])

    result = Tickets::MarkNoShowService.new(
      current_user: current_user,
      ticket: ticket
    ).call

    if result.success?
      redirect_to agent_queue_path(
        service_window_id: result.ticket.service_window_id
      ),
                  notice: "Ticket #{result.ticket.ticket_number} marked as no-show."
    else
      redirect_to agent_queue_path(
        service_window_id: ticket&.service_window_id ||
          params[:service_window_id]
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
        assigned_agent: current_user,
        status: "called"
      )
      .order(called_at: :desc, id: :desc)
      .first
  end

  def current_in_attention_ticket_for(service_window)
    return unless service_window

    Ticket
      .includes(:queue_service, :service_window, :assigned_agent)
      .where(
        service_window: service_window,
        assigned_agent: current_user,
        status: "in_attention"
      )
      .order(started_at: :desc, id: :desc)
      .first
  end

  def service_window_busy?(service_window)
    return false unless service_window

    Ticket.exists?(
      service_window: service_window,
      status: %w[called in_attention]
    )
  end

  def active_ticket_for_current_user
    Ticket
      .includes(:service_window)
      .where(
        assigned_agent: current_user,
        status: %w[called in_attention]
      )
      .order(updated_at: :desc, id: :desc)
      .first
  end

  def serialize_agent_active_ticket(ticket)
    return unless ticket

    {
      id: ticket.id,
      ticket_number: ticket.ticket_number,
      status: ticket.status,
      service_window: {
        id: ticket.service_window.id,
        name: ticket.service_window.name,
        code: ticket.service_window.code
      }
    }
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

    serialize_active_ticket(ticket).merge(
      called_at: ticket.called_at&.iso8601
    )
  end

  def serialize_current_in_attention_ticket(service_window)
    ticket = current_in_attention_ticket_for(service_window)

    return unless ticket

    serialize_active_ticket(ticket).merge(
      started_at: ticket.started_at&.iso8601
    )
  end

  def serialize_active_ticket(ticket)
    {
      id: ticket.id,
      ticket_number: ticket.ticket_number,
      priority: ticket.priority,
      assistance_type: ticket.assistance_type,
      intake_source: ticket.intake_source,
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
