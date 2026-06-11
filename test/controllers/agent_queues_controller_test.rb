require "test_helper"

class AgentQueuesControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 11, 0, 0)

    @service_window = service_windows(:window_one)
    @pending_ticket = tickets(:self_service_ticket)
  end

  teardown do
    travel_back
  end

  test "redirects unauthenticated users to login" do
    get agent_queue_url

    assert_redirected_to login_url
  end

  test "allows an agent to access the agent queue" do
    login_as(users(:agent_user))

    get agent_queue_url

    assert_response :success
  end

  test "allows an admin to access the agent queue" do
    login_as(users(:admin_user))

    get agent_queue_url

    assert_response :success
  end

  test "does not allow a receptionist to access the agent queue" do
    login_as(users(:receptionist_user))

    get agent_queue_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "does not allow a supervisor to access the agent queue" do
    login_as(users(:supervisor_user))

    get agent_queue_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "calls the next ticket with valid parameters" do
    agent = users(:agent_user)
    login_as(agent)

    post call_next_ticket_url, params: {
      service_window_id: @service_window.id
    }

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "called", @pending_ticket.status
    assert_equal agent, @pending_ticket.assigned_agent
    assert_equal @service_window, @pending_ticket.service_window
    assert_equal Time.current, @pending_ticket.called_at
    assert_equal(
      "Ticket #{@pending_ticket.ticket_number} called successfully.",
      flash[:notice]
    )
  end

  test "shows an error when there are no pending tickets" do
    login_as(users(:agent_user))

    Ticket.where(
      queue_service: @service_window.queue_service,
      status: "pending"
    ).update_all(status: "cancelled")

    post call_next_ticket_url, params: {
      service_window_id: @service_window.id
    }

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal(
      "No pending tickets are available for this service",
      flash[:alert]
    )
  end

  test "agent starts assigned called ticket" do
    agent = users(:agent_user)
    prepare_called_ticket(assigned_agent: agent)
    login_as(agent)

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "in_attention", @pending_ticket.status
    assert_equal Time.current, @pending_ticket.started_at
    assert_equal(
      "Ticket #{@pending_ticket.ticket_number} attention started successfully.",
      flash[:notice]
    )
  end

  test "admin starts own assigned called ticket" do
    admin = users(:admin_user)
    prepare_called_ticket(assigned_agent: admin)
    login_as(admin)

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "in_attention", @pending_ticket.status
    assert_equal admin, @pending_ticket.assigned_agent
    assert_equal Time.current, @pending_ticket.started_at
  end

  test "cannot start ticket assigned to another agent" do
    prepare_called_ticket(assigned_agent: users(:admin_user))
    login_as(users(:agent_user))

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "called", @pending_ticket.reload.status
    assert_nil @pending_ticket.started_at
    assert_equal "Ticket is assigned to another agent", flash[:alert]
  end

  test "cannot start ticket with invalid status" do
    agent = users(:agent_user)
    @pending_ticket.update!(
      assigned_agent: agent,
      service_window: @service_window,
      status: "pending"
    )
    login_as(agent)

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "pending", @pending_ticket.reload.status
    assert_nil @pending_ticket.started_at
    assert_equal(
      "Ticket must be called before attention can start",
      flash[:alert]
    )
  end

  test "agent finishes own in attention ticket" do
    agent = users(:agent_user)
    prepare_in_attention_ticket(assigned_agent: agent)
    login_as(agent)

    patch finish_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "attended", @pending_ticket.status
    assert_equal Time.current, @pending_ticket.finished_at
    assert_equal(
      "Ticket #{@pending_ticket.ticket_number} attention finished successfully.",
      flash[:notice]
    )
  end

  test "cannot finish ticket assigned to another agent" do
    prepare_in_attention_ticket(assigned_agent: users(:admin_user))
    login_as(users(:agent_user))

    patch finish_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "in_attention", @pending_ticket.reload.status
    assert_nil @pending_ticket.finished_at
    assert_equal "Ticket is assigned to another agent", flash[:alert]
  end

  test "cannot finish ticket with invalid status" do
    agent = users(:agent_user)
    prepare_called_ticket(assigned_agent: agent)
    login_as(agent)

    patch finish_ticket_attention_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "called", @pending_ticket.reload.status
    assert_nil @pending_ticket.finished_at
    assert_equal(
      "Ticket must be in attention before attention can finish",
      flash[:alert]
    )
  end

  test "agent marks own called ticket as no show" do
    agent = users(:agent_user)
    prepare_called_ticket(assigned_agent: agent)
    login_as(agent)

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "no_show", @pending_ticket.status
    assert_equal Time.current, @pending_ticket.no_show_at
    assert_equal agent, @pending_ticket.assigned_agent
    assert_equal @service_window, @pending_ticket.service_window
    assert_equal(
      "Ticket #{@pending_ticket.ticket_number} marked as no-show.",
      flash[:notice]
    )
  end

  test "admin marks own called ticket as no show" do
    admin = users(:admin_user)
    prepare_called_ticket(assigned_agent: admin)
    login_as(admin)

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    @pending_ticket.reload

    assert_equal "no_show", @pending_ticket.status
    assert_equal Time.current, @pending_ticket.no_show_at
    assert_equal admin, @pending_ticket.assigned_agent
    assert_equal @service_window, @pending_ticket.service_window
  end

  test "cannot mark ticket assigned to another agent as no show" do
    prepare_called_ticket(assigned_agent: users(:admin_user))
    login_as(users(:agent_user))

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "called", @pending_ticket.reload.status
    assert_nil @pending_ticket.no_show_at
    assert_equal "Ticket is assigned to another agent", flash[:alert]
  end

  test "cannot mark ticket with invalid status as no show" do
    agent = users(:agent_user)
    @pending_ticket.update!(
      assigned_agent: agent,
      service_window: @service_window,
      status: "pending",
      called_at: nil,
      no_show_at: nil
    )
    login_as(agent)

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "pending", @pending_ticket.reload.status
    assert_nil @pending_ticket.no_show_at
    assert_equal(
      "Ticket must be called before it can be marked as no-show",
      flash[:alert]
    )
  end

  test "receptionist cannot use mark no show" do
    prepare_called_ticket(assigned_agent: users(:agent_user))
    login_as(users(:receptionist_user))

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal "called", @pending_ticket.reload.status
    assert_nil @pending_ticket.no_show_at
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "supervisor cannot use mark no show" do
    prepare_called_ticket(assigned_agent: users(:agent_user))
    login_as(users(:supervisor_user))

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal "called", @pending_ticket.reload.status
    assert_nil @pending_ticket.no_show_at
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "agent can call another ticket after previous ticket becomes no show" do
    agent = users(:agent_user)
    prepare_called_ticket(assigned_agent: agent)

    next_ticket = Ticket.create!(
      queue_service: @service_window.queue_service,
      ticket_number: "ADM-002",
      sequence_date: Date.new(2026, 6, 9),
      daily_sequence: 2,
      priority: "normal",
      priority_weight: 6,
      status: "pending",
      intake_source: "self_service"
    )

    login_as(agent)

    patch mark_ticket_no_show_url(@pending_ticket)

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    assert_equal "no_show", @pending_ticket.reload.status

    post call_next_ticket_url, params: {
      service_window_id: @service_window.id
    }

    assert_redirected_to agent_queue_url(
      service_window_id: @service_window.id
    )

    next_ticket.reload

    assert_equal "called", next_ticket.status
    assert_equal agent, next_ticket.assigned_agent
    assert_equal @service_window, next_ticket.service_window
    assert_equal Time.current, next_ticket.called_at
  end

  test "receptionist cannot use attention actions" do
    prepare_called_ticket(assigned_agent: users(:agent_user))
    login_as(users(:receptionist_user))

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )

    patch finish_ticket_attention_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "supervisor cannot use attention actions" do
    prepare_called_ticket(assigned_agent: users(:agent_user))
    login_as(users(:supervisor_user))

    patch start_ticket_attention_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )

    patch finish_ticket_attention_url(@pending_ticket)

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  private

  def prepare_called_ticket(assigned_agent:)
    @pending_ticket.update!(
      assigned_agent: assigned_agent,
      service_window: @service_window,
      status: "called",
      called_at: 5.minutes.ago,
      started_at: nil,
      finished_at: nil
    )
  end

  def prepare_in_attention_ticket(assigned_agent:)
    @pending_ticket.update!(
      assigned_agent: assigned_agent,
      service_window: @service_window,
      status: "in_attention",
      called_at: 10.minutes.ago,
      started_at: 5.minutes.ago,
      finished_at: nil
    )
  end

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
