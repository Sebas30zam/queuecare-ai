require "test_helper"

class Tickets::CancelTicketServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 10, 10, 0, 0)

    @admin = users(:admin_user)
    @receptionist = users(:receptionist_user)
    @agent = users(:agent_user)
    @supervisor = users(:supervisor_user)
    @ticket = tickets(:self_service_ticket)

    @original_ticket_number = @ticket.ticket_number
    @original_queue_service = @ticket.queue_service

    @ticket.update!(
      status: "pending",
      cancelled_at: nil
    )
  end

  teardown do
    travel_back
  end

  test "cancels a pending ticket" do
    result = cancel_ticket

    assert result.success?
    assert_equal @ticket, result.ticket
    assert_empty result.errors
  end

  test "changes status to cancelled" do
    result = cancel_ticket

    assert result.success?
    assert_equal "cancelled", @ticket.reload.status
  end

  test "sets cancelled at" do
    result = cancel_ticket

    assert result.success?
    assert_equal Time.current, @ticket.reload.cancelled_at
  end

  test "preserves ticket number" do
    result = cancel_ticket

    assert result.success?
    assert_equal @original_ticket_number, @ticket.reload.ticket_number
  end

  test "preserves queue service" do
    result = cancel_ticket

    assert result.success?
    assert_equal @original_queue_service, @ticket.reload.queue_service
  end

  test "rejects called ticket" do
    @ticket.update!(
      status: "called",
      called_at: 1.minute.ago
    )

    result = cancel_ticket

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be pending before it can be cancelled"
    )
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects in attention ticket" do
    @ticket.update!(
      status: "in_attention",
      called_at: 5.minutes.ago,
      started_at: 2.minutes.ago
    )

    result = cancel_ticket

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be pending before it can be cancelled"
    )
    assert_equal "in_attention", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects attended ticket" do
    @ticket.update!(
      status: "attended",
      called_at: 8.minutes.ago,
      started_at: 6.minutes.ago,
      finished_at: 1.minute.ago
    )

    result = cancel_ticket

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be pending before it can be cancelled"
    )
    assert_equal "attended", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects no show ticket" do
    @ticket.update!(
      status: "no_show",
      called_at: 8.minutes.ago,
      no_show_at: 1.minute.ago
    )

    result = cancel_ticket

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be pending before it can be cancelled"
    )
    assert_equal "no_show", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects already cancelled ticket" do
    previous_cancelled_at = 1.minute.ago

    @ticket.update!(
      status: "cancelled",
      cancelled_at: previous_cancelled_at
    )

    result = cancel_ticket

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be pending before it can be cancelled"
    )
    assert_equal "cancelled", @ticket.reload.status
    assert_equal previous_cancelled_at, @ticket.cancelled_at
  end

  test "rejects missing user" do
    result = Tickets::CancelTicketService.new(
      current_user: nil,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes result.errors, "Current user is required"
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects agent role" do
    result = Tickets::CancelTicketService.new(
      current_user: @agent,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to cancel tickets"
    )
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "rejects supervisor role" do
    result = Tickets::CancelTicketService.new(
      current_user: @supervisor,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to cancel tickets"
    )
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.cancelled_at
  end

  test "allows receptionist role" do
    result = Tickets::CancelTicketService.new(
      current_user: @receptionist,
      ticket: @ticket
    ).call

    assert result.success?
    assert_equal "cancelled", @ticket.reload.status
    assert_equal Time.current, @ticket.cancelled_at
  end

  private

  def cancel_ticket
    Tickets::CancelTicketService.new(
      current_user: @admin,
      ticket: @ticket
    ).call
  end
end
