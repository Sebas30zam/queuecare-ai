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

  test "rejects calling another ticket when agent has a called ticket" do
    active_ticket = tickets(:self_service_ticket)
    active_ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "called",
      called_at: 5.minutes.ago
    )

    pending_ticket = create_pending_ticket(
      ticket_number: "ADM-020",
      daily_sequence: 20,
      priority: "normal",
      priority_weight: 6,
      created_at: 1.minute.ago
    )

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes(
      result.errors,
      "The agent already has an active ticket"
    )
    assert_equal "pending", pending_ticket.reload.status
  end

  test "rejects calling another ticket when agent has an in attention ticket" do
    active_ticket = tickets(:self_service_ticket)
    active_ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "in_attention",
      called_at: 10.minutes.ago,
      started_at: 5.minutes.ago
    )

    pending_ticket = create_pending_ticket(
      ticket_number: "ADM-021",
      daily_sequence: 21,
      priority: "normal",
      priority_weight: 6,
      created_at: 1.minute.ago
    )

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes(
      result.errors,
      "The agent already has an active ticket"
    )
    assert_equal "pending", pending_ticket.reload.status
  end

  test "allows calling after previous ticket is attended" do
    previous_ticket = tickets(:self_service_ticket)
    previous_ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "attended",
      called_at: 10.minutes.ago,
      started_at: 5.minutes.ago,
      finished_at: 1.minute.ago
    )

    next_ticket = create_pending_ticket(
      ticket_number: "ADM-022",
      daily_sequence: 22,
      priority: "normal",
      priority_weight: 6,
      created_at: 1.minute.ago
    )

    result = call_next_ticket

    assert result.success?
    assert_equal next_ticket, result.ticket
    assert_equal "called", next_ticket.reload.status
    assert_equal @agent, next_ticket.assigned_agent
    assert_equal @service_window, next_ticket.service_window
  end

  test "rejects calling from a service window with an active ticket" do
    active_ticket = tickets(:self_service_ticket)
    active_ticket.update!(
      assigned_agent: users(:admin_user),
      service_window: @service_window,
      status: "called",
      called_at: 5.minutes.ago
    )

    pending_ticket = create_pending_ticket(
      ticket_number: "ADM-023",
      daily_sequence: 23,
      priority: "normal",
      priority_weight: 6,
      created_at: 1.minute.ago
    )

    result = call_next_ticket

    assert_not result.success?
    assert_nil result.ticket
    assert_includes(
      result.errors,
      "The service window already has an active ticket"
    )
    assert_equal "pending", pending_ticket.reload.status
  end

  test "allows different agents to call from different windows of the same service" do
    first_ticket = tickets(:self_service_ticket)
    first_ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "in_attention",
      called_at: 10.minutes.ago,
      started_at: 5.minutes.ago
    )

    second_window = ServiceWindow.create!(
      queue_service: @queue_service,
      name: "Admissions Window 2",
      code: "ADM-W2",
      active: true
    )

    pending_ticket = create_pending_ticket(
      ticket_number: "ADM-024",
      daily_sequence: 24,
      priority: "normal",
      priority_weight: 6,
      created_at: 1.minute.ago
    )

    second_agent = users(:admin_user)

    result = Tickets::CallNextTicketService.new(
      current_user: second_agent,
      service_window: second_window
    ).call

    assert result.success?
    assert_equal pending_ticket, result.ticket

    pending_ticket.reload

    assert_equal "called", pending_ticket.status
    assert_equal second_agent, pending_ticket.assigned_agent
    assert_equal second_window, pending_ticket.service_window
    assert_equal "in_attention", first_ticket.reload.status
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
