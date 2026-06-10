require "test_helper"

class Tickets::CallNextTicketServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 11, 0, 0)

    @agent = users(:agent_user)
    @service_window = service_windows(:window_one)
    @queue_service = queue_services(:admissions)
  end

  teardown do
    travel_back
  end

  test "calls the oldest normal ticket" do
    older_ticket = create_pending_ticket(
      ticket_number: "ADM-010",
      daily_sequence: 10,
      priority: "normal",
      priority_weight: 6,
      created_at: 20.minutes.ago
    )

    create_pending_ticket(
      ticket_number: "ADM-011",
      daily_sequence: 11,
      priority: "normal",
      priority_weight: 6,
      created_at: 10.minutes.ago
    )

    result = call_next_ticket

    assert result.success?
    assert_equal older_ticket, result.ticket
  end

  test "respects priority weight before arrival time" do
    create_pending_ticket(
      ticket_number: "ADM-012",
      daily_sequence: 12,
      priority: "normal",
      priority_weight: 6,
      created_at: 30.minutes.ago
    )

    priority_ticket = create_pending_ticket(
      ticket_number: "ADM-013",
      daily_sequence: 13,
      priority: "senior",
      priority_weight: 3,
      assistance_type: "senior",
      created_at: 5.minutes.ago
    )

    result = call_next_ticket

    assert result.success?
    assert_equal priority_ticket, result.ticket
  end

  test "respects created at within the same priority" do
    older_ticket = create_pending_ticket(
      ticket_number: "ADM-014",
      daily_sequence: 14,
      priority: "senior",
      priority_weight: 3,
      assistance_type: "senior",
      created_at: 15.minutes.ago
    )

    create_pending_ticket(
      ticket_number: "ADM-015",
      daily_sequence: 15,
      priority: "senior",
      priority_weight: 3,
      assistance_type: "senior",
      created_at: 5.minutes.ago
    )

    result = call_next_ticket

    assert result.success?
    assert_equal older_ticket, result.ticket
  end

  test "only selects tickets from the service window queue service" do
    finance_ticket = tickets(:assisted_senior_ticket)
    admissions_ticket = tickets(:self_service_ticket)

    result = call_next_ticket

    assert result.success?
    assert_equal admissions_ticket, result.ticket
    assert_equal "pending", finance_ticket.reload.status
  end

  test "assigns agent and service window and changes status to called" do
    ticket = tickets(:self_service_ticket)

    result = call_next_ticket

    assert result.success?

    ticket.reload

    assert_equal @agent, ticket.assigned_agent
    assert_equal @service_window, ticket.service_window
    assert_equal "called", ticket.status
  end

  test "records called at" do
    result = call_next_ticket

    assert result.success?
    assert_equal Time.current, result.ticket.reload.called_at
  end

  test "rejects an inactive service window" do
    @service_window.update!(active: false)

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes result.errors, "Service window is inactive"
    assert_equal "pending", tickets(:self_service_ticket).reload.status
  end

  test "rejects an inactive queue service" do
    @queue_service.update!(active: false)
    @service_window.reload

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes result.errors, "Queue service is inactive"
    assert_equal "pending", tickets(:self_service_ticket).reload.status
  end

  test "returns an error when there are no pending tickets" do
    Ticket.where(
      queue_service: @queue_service,
      status: "pending"
    ).update_all(status: "cancelled")

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes(
      result.errors,
      "No pending tickets are available for this service"
    )
  end

  test "does not call the same ticket twice" do
    first_result = call_next_ticket
    second_result = call_next_ticket

    assert first_result.success?
    assert_not second_result.success?
    assert_equal "called", first_result.ticket.reload.status
    assert_includes(
      second_result.errors,
      "No pending tickets are available for this service"
    )
  end

  test "rejects a user without an allowed role" do
    result = Tickets::CallNextTicketService.new(
      current_user: users(:receptionist_user),
      service_window: @service_window
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to call tickets"
    )
  end

  private

  def call_next_ticket
    Tickets::CallNextTicketService.new(
      current_user: @agent,
      service_window: @service_window
    ).call
  end

  def create_pending_ticket(
    ticket_number:,
    daily_sequence:,
    priority:,
    priority_weight:,
    created_at:,
    assistance_type: nil
  )
    Ticket.create!(
      queue_service: @queue_service,
      ticket_number: ticket_number,
      sequence_date: Date.current,
      daily_sequence: daily_sequence,
      priority: priority,
      priority_weight: priority_weight,
      status: "pending",
      intake_source: "self_service",
      assistance_type: assistance_type,
      created_at: created_at,
      updated_at: created_at
    )
  end
end
