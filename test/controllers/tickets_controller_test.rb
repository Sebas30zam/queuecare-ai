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

  private

  def sign_in_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
