class SelfServiceTicketsController < ApplicationController
  def new
    queue_services = QueueService.where(active: true).order(:name).map do |queue_service|
      {
        id: queue_service.id,
        name: queue_service.name,
        code: queue_service.code
      }
    end

    render inertia: "self-service/tickets/new", props: {
      queue_services: queue_services,
      assistance_types: Ticket::ASSISTANCE_TYPES,
      generated_ticket: flash[:generated_ticket]
    }
  end

  def create
    result = Tickets::CreateTicketService.new(
      current_user: nil,
      params: self_service_ticket_params
    ).call

    if result.success?
      flash[:generated_ticket] = {
        ticket_number: result.ticket.ticket_number,
        service_name: result.ticket.queue_service.name,
        assistance_type: result.ticket.assistance_type
      }

      redirect_to self_service_path
    else
      redirect_to self_service_path,
                  alert: result.errors.to_sentence
    end
  end

  private

  def self_service_ticket_params
    params.require(:ticket)
          .permit(:queue_service_id, :assistance_type)
          .to_h
          .merge(intake_source: "self_service")
  end
end
