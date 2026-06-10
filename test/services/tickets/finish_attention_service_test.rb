require "test_helper"

class Tickets::FinishAttentionServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 11, 45, 0)

    @agent = users(:agent_user)
    @service_window = service_windows(:window_one)
    @ticket = tickets(:self_service_ticket)
    @called_at = 10.minutes.ago
    @started_at = 5.minutes.ago

    @ticket.update!(
      assigned_agent: @agent,
      service_window: @service_window,
      status: "in_attention",
      called_at: @called_at,
      started_at: @started_at
    )
  end

  teardown do
    travel_back
  end

  test "finishes an in attention ticket" do
    result = finish_attention

    assert result.success?
    assert_equal @ticket, result.ticket
    assert_empty result.errors
  end

  test "changes status to attended" do
    result = finish_attention

    assert result.success?
    assert_equal "attended", @ticket.reload.status
  end

  test "sets finished at" do
    result = finish_attention

    assert result.success?
    assert_equal Time.current, @ticket.reload.finished_at
  end

  test "preserves started at" do
    result = finish_attention

    assert result.success?
    assert_equal @started_at, @ticket.reload.started_at
  end

  test "rejects called ticket" do
    @ticket.update!(
      status: "called",
      started_at: nil
    )

    result = finish_attention

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be in attention before attention can finish"
    )
    assert_equal "called", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  test "rejects pending ticket" do
    @ticket.update!(
      status: "pending",
      started_at: nil
    )

    result = finish_attention

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be in attention before attention can finish"
    )
    assert_equal "pending", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  test "rejects attended ticket" do
    @ticket.update!(status: "attended")

    result = finish_attention

    assert_not result.success?
    assert_includes(
      result.errors,
      "Ticket must be in attention before attention can finish"
    )
    assert_equal "attended", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  test "rejects ticket assigned to another agent" do
    @ticket.update!(assigned_agent: users(:admin_user))

    result = finish_attention

    assert_not result.success?
    assert_includes result.errors, "Ticket is assigned to another agent"
    assert_equal "in_attention", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  test "rejects missing user" do
    result = Tickets::FinishAttentionService.new(
      current_user: nil,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes result.errors, "Current user is required"
    assert_equal "in_attention", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  test "rejects unauthorized role" do
    receptionist = users(:receptionist_user)
    @ticket.update!(assigned_agent: receptionist)

    result = Tickets::FinishAttentionService.new(
      current_user: receptionist,
      ticket: @ticket
    ).call

    assert_not result.success?
    assert_includes(
      result.errors,
      "Current user is not authorized to finish attention"
    )
    assert_equal "in_attention", @ticket.reload.status
    assert_nil @ticket.finished_at
  end

  private

  def finish_attention
    Tickets::FinishAttentionService.new(
      current_user: @agent,
      ticket: @ticket
    ).call
  end
end
