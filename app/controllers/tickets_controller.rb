class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :receptionist) }

  def reception
    queue_services = QueueService.where(active: true).order(:name).map do |queue_service|
      {
        id: queue_service.id,
        name: queue_service.name,
        code: queue_service.code
      }
    end

    recent_tickets = Ticket.includes(:queue_service)
                           .order(created_at: :desc)
                           .limit(10)
                           .map do |ticket|
      {
        id: ticket.id,
        ticket_number: ticket.ticket_number,
        service: {
          id: ticket.queue_service.id,
          name: ticket.queue_service.name,
          code: ticket.queue_service.code
        },
        priority: ticket.priority,
        assistance_type: ticket.assistance_type,
        intake_source: ticket.intake_source,
        status: ticket.status,
        created_at: ticket.created_at.iso8601
      }
    end

    render inertia: "tickets/reception", props: {
      queue_services: queue_services,
      assistance_types: Ticket::ASSISTANCE_TYPES,
      recent_tickets: recent_tickets
    }
  end

  def create
    result = Tickets::CreateTicketService.new(
      current_user: current_user,
      params: assisted_ticket_params
    ).call

    if result.success?
      redirect_to tickets_reception_path,
                  notice: "Ticket #{result.ticket.ticket_number} created successfully."
    else
      redirect_to tickets_reception_path,
                  alert: result.errors.to_sentence
    end
  end

  private

  def assisted_ticket_params
    params.require(:ticket)
          .permit(:queue_service_id, :assistance_type)
          .to_h
          .merge(intake_source: "assisted")
  end
end
