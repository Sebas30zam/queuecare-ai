require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 10, 0, 0)
  end

  teardown do
    travel_back
  end

  test "redirects unauthenticated user to login" do
    get tickets_reception_url

    assert_redirected_to login_url
  end

  test "admin can access assisted ticket intake" do
    sign_in_as(users(:admin_user))

    get tickets_reception_url

    assert_response :success
  end

  test "receptionist can access assisted ticket intake" do
    sign_in_as(users(:receptionist_user))

    get tickets_reception_url

    assert_response :success
  end

  test "agent cannot access assisted ticket intake" do
    sign_in_as(users(:agent_user))

    get tickets_reception_url

    assert_redirected_to root_url
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  test "supervisor cannot access assisted ticket intake" do
    sign_in_as(users(:supervisor_user))

    get tickets_reception_url

    assert_redirected_to root_url
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  test "receptionist creates an assisted normal ticket" do
    receptionist = users(:receptionist_user)

    sign_in_as(receptionist)

    assert_difference "Ticket.count", 1 do
      post tickets_url, params: {
        ticket: {
          queue_service_id: queue_services(:admissions).id,
          assistance_type: ""
        }
      }
    end

    assert_redirected_to tickets_reception_url

    ticket = Ticket.find_by!(
      ticket_number: "ADM-002",
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_equal "assisted", ticket.intake_source
    assert_equal "normal", ticket.priority
    assert_equal 6, ticket.priority_weight
    assert_equal "pending", ticket.status
    assert_nil ticket.assistance_type
    assert_equal receptionist, ticket.created_by
    assert_equal 2, daily_sequences(:admissions_today).reload.current_number
    assert_equal "Ticket ADM-002 created successfully.", flash[:notice]
  end

  test "assisted intake maps assistance type to priority" do
    sign_in_as(users(:admin_user))

    assert_difference "Ticket.count", 1 do
      post tickets_url, params: {
        ticket: {
          queue_service_id: queue_services(:finance).id,
          assistance_type: "senior"
        }
      }
    end

    ticket = Ticket.find_by!(
      ticket_number: "FIN-002",
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_equal "assisted", ticket.intake_source
    assert_equal "senior", ticket.assistance_type
    assert_equal "senior", ticket.priority
    assert_equal 3, ticket.priority_weight
    assert_equal users(:admin_user), ticket.created_by
  end

  test "admin can cancel pending ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(status: "pending", cancelled_at: nil)

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "cancelled", ticket.reload.status
    assert_equal Time.current, ticket.cancelled_at
    assert_equal "Ticket #{ticket.ticket_number} cancelled successfully.", flash[:notice]
  end

  test "receptionist can cancel pending ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(status: "pending", cancelled_at: nil)

    sign_in_as(users(:receptionist_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "cancelled", ticket.reload.status
    assert_equal Time.current, ticket.cancelled_at
    assert_equal "Ticket #{ticket.ticket_number} cancelled successfully.", flash[:notice]
  end

  test "agent cannot cancel ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(status: "pending", cancelled_at: nil)

    sign_in_as(users(:agent_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to root_url
    assert_equal "You are not authorized to access this page.", flash[:alert]
    assert_equal "pending", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "supervisor cannot cancel ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(status: "pending", cancelled_at: nil)

    sign_in_as(users(:supervisor_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to root_url
    assert_equal "You are not authorized to access this page.", flash[:alert]
    assert_equal "pending", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "cannot cancel called ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(
      assigned_agent: users(:agent_user),
      service_window: service_windows(:window_one),
      status: "called",
      called_at: 1.minute.ago,
      cancelled_at: nil
    )

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "Ticket must be pending before it can be cancelled", flash[:alert]
    assert_equal "called", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "cannot cancel in attention ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(
      assigned_agent: users(:agent_user),
      service_window: service_windows(:window_one),
      status: "in_attention",
      called_at: 5.minutes.ago,
      started_at: 2.minutes.ago,
      cancelled_at: nil
    )

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "Ticket must be pending before it can be cancelled", flash[:alert]
    assert_equal "in_attention", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "cannot cancel attended ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(
      assigned_agent: users(:agent_user),
      service_window: service_windows(:window_one),
      status: "attended",
      called_at: 8.minutes.ago,
      started_at: 6.minutes.ago,
      finished_at: 1.minute.ago,
      cancelled_at: nil
    )

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "Ticket must be pending before it can be cancelled", flash[:alert]
    assert_equal "attended", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "cannot cancel no show ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(
      assigned_agent: users(:agent_user),
      service_window: service_windows(:window_one),
      status: "no_show",
      called_at: 8.minutes.ago,
      no_show_at: 1.minute.ago,
      cancelled_at: nil
    )

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "Ticket must be pending before it can be cancelled", flash[:alert]
    assert_equal "no_show", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  test "cancelled ticket shows alert if cancelled again" do
    ticket = tickets(:self_service_ticket)
    previous_cancelled_at = 1.minute.ago

    ticket.update!(
      status: "cancelled",
      cancelled_at: previous_cancelled_at
    )

    sign_in_as(users(:admin_user))

    patch cancel_ticket_url(ticket)

    assert_redirected_to tickets_reception_url
    assert_equal "Ticket must be pending before it can be cancelled", flash[:alert]
    assert_equal "cancelled", ticket.reload.status
    assert_equal previous_cancelled_at, ticket.cancelled_at
  end

  test "user without login is redirected when cancelling ticket" do
    ticket = tickets(:self_service_ticket)
    ticket.update!(status: "pending", cancelled_at: nil)

    patch cancel_ticket_url(ticket)

    assert_redirected_to login_url
    assert_equal "pending", ticket.reload.status
    assert_nil ticket.cancelled_at
  end

  private

  def sign_in_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
