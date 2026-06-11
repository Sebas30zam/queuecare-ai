require "test_helper"

class Tickets::MarkNoShowServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 11, 50, 0)

    @agent = users(:agent_user)
    @service_window = service_windows(:window_one)
    @ticket = tickets(:self_service_ticket)
    @called_at = 5.minutes.ago

    @ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "called",
      called_at: @called_at,
      no_show_at: nil
    )
  end

  teardown do
    travel_back
  end

  test "marks a called ticket as no show" do
    result = mark_no_show

    assert result.success?
    assert_equal @ticket, result.ticket
    assert_empty result.errors
    assert_equal "no_show", @ticket.reload.status
  end

  test "sets no show at" do
    result = mark_no_show

    assert result.success?
    assert_equal Time.current, @ticket.reload.no_show_at
  end

  test "preserves called at" do
    result = mark_no_show

    assert result.success?
    assert_equal @called_at, @ticket.reload.called_at
  end

  test "preserves assigned agent" do
    result = mark_no_show

    assert result.success?
    assert_equal @agent, @ticket.reload.assigned_agent
  end

  test "preserves service window" do
    result = mark_no_show

    assert result.success?
    assert_equal @service_window, @ticket.reload.service_window
  end

  test "rejects recently called ticket" do
    @ticket.update!(called_at: 10.seconds.ago)

    result = mark_no_show

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket can only be marked as no-show 15 seconds after it was called"
    )
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects pending ticket" do
    @ticket.update!(status: "pending")

    result = mark_no_show

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before it can be marked as no-show"
    )
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects in attention ticket" do
    @ticket.update!(
      status: "in_attention",
      started_at: 2.minutes.ago
    )

    result = mark_no_show

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before it can be marked as no-show"
    )
    assert_equal "in_attention", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects attended ticket" do
    @ticket.update!(
      status: "attended",
      started_at: 4.minutes.ago,
      finished_at: 1.minute.ago
    )

    result = mark_no_show

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before it can be marked as no-show"
    )
    assert_equal "attended", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects cancelled ticket" do
    @ticket.update!(
      status: "cancelled",
      cancelled_at: 1.minute.ago
    )

    result = mark_no_show

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before it can be marked as no-show"
    )
    assert_equal "cancelled", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects ticket assigned to another agent" do
    @ticket.update!(assigned_agent: users(:admin_user))

    result = mark_no_show

    assert_not result.success?
    assert_includes result.errors, "Ticket is assigned to another agent"
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects missing user" do
    result = Tickets::MarkNoShowService.new(
      current_user: nil,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes result.errors, "Current user is required"
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  test "rejects unauthorized role" do
    receptionist = users(:receptionist_user)
    @ticket.update!(assigned_agent: receptionist)

    result = Tickets::MarkNoShowService.new(
      current_user: receptionist,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to mark tickets as no-show"
    )
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.no_show_at
  end

  private

  def mark_no_show
    Tickets::MarkNoShowService.new(
      current_user: @agent,
      ticket: @ticket
    ).call
  end
end
