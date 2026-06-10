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

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
