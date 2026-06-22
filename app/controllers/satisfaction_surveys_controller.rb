class SatisfactionSurveysController < ApplicationController
  def show
    ticket = eligible_ticket

    return head :not_found unless ticket

    render_survey_page(ticket:)
  end

  def create
    ticket = find_ticket

    return head :not_found unless ticket

    result = SatisfactionSurveys::CreateSurveyService.new(
      ticket: ticket,
      rating: survey_params[:rating],
      comment: survey_params[:comment]
    ).call

    if result.success?
      render_survey_page(
        ticket: ticket,
        submitted: true
      )
    else
      render_survey_page(
        ticket: ticket,
        errors: result.errors,
        status: :unprocessable_entity
      )
    end
  end

  private

  def find_ticket
    Ticket.includes(
      :queue_service,
      :service_window,
      :satisfaction_survey
    ).find_by(survey_token: params[:survey_token])
  end

  def eligible_ticket
    ticket = find_ticket

    return unless ticket
    return unless ticket.status == "attended"
    return if ticket.finished_at.blank?
    return if ticket.satisfaction_survey.present?

    ticket
  end

  def survey_params
    params.permit(:rating, :comment)
  end

  def render_survey_page(
    ticket:,
    submitted: false,
    errors: [],
    status: :ok
  )
    render inertia: "satisfaction-surveys/show",
           props: {
             ticket: serialize_ticket(ticket),
             submitted: submitted,
             errors: errors
           },
           status: status
  end

  def serialize_ticket(ticket)
    {
      ticket_number: ticket.ticket_number,
      status: ticket.status,
      queue_service: {
        id: ticket.queue_service.id,
        name: ticket.queue_service.name,
        code: ticket.queue_service.code
      },
      service_window: serialize_service_window(ticket.service_window)
    }
  end

  def serialize_service_window(service_window)
    return unless service_window

    {
      id: service_window.id,
      name: service_window.name,
      code: service_window.code
    }
  end
end
