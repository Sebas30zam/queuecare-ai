require "test_helper"

class Tickets::StartAttentionServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 11, 30, 0)

    @agent = users(:agent_user)
    @service_window = service_windows(:window_one)
    @ticket = tickets(:self_service_ticket)
    @called_at = 5.minutes.ago

    @ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "called",
      called_at: @called_at
    )
  end

  teardown do
    travel_back
  end

  test "starts a called ticket" do
    result = start_attention

    assert result.success?
    assert_equal @ticket, result.ticket
    assert_empty result.errors
  end

  test "changes status to in attention" do
    result = start_attention

    assert result.success?
    assert_equal "in_attention", @ticket.reload.status
  end

  test "sets started at" do
    result = start_attention

    assert result.success?
    assert_equal Time.current, @ticket.reload.started_at
  end

  test "preserves called at" do
    result = start_attention

    assert result.success?
    assert_equal @called_at, @ticket.reload.called_at
  end

  test "preserves assigned agent" do
    result = start_attention

    assert result.success?
    assert_equal @agent, @ticket.reload.assigned_agent
  end

  test "preserves service window" do
    result = start_attention

    assert result.success?
    assert_equal @service_window, @ticket.reload.service_window
  end

  test "rejects pending ticket" do
    @ticket.update!(status: "pending")

    result = start_attention

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before attention can start"
    )
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.started_at
  end

  test "rejects attended ticket" do
    @ticket.update!(status: "attended")

    result = start_attention

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be called before attention can start"
    )
    assert_equal "attended", @ticket.reload.status
    assert_nil @ticket.started_at
  end

  test "rejects ticket assigned to another agent" do
    @ticket.update!(assigned_agent: users(:admin_user))

    result = start_attention

    assert_not result.success?
    assert_includes result.errors, "Ticket is assigned to another agent"
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.started_at
  end

  test "rejects missing user" do
    result = Tickets::StartAttentionService.new(
      current_user: nil,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes result.errors, "Current user is required"
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.started_at
  end

  test "rejects unauthorized role" do
    receptionist = users(:receptionist_user)
    @ticket.update!(assigned_agent: receptionist)

    result = Tickets::StartAttentionService.new(
      current_user: receptionist,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to start attention"
    )
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.started_at
  end

  private

  def start_attention
    Tickets::StartAttentionService.new(
      current_user: @agent,
      ticket: @ticket
    ).call
  end
end
