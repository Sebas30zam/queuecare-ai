require "test_helper"

class SelfServiceTicketsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 10, 0, 0)
  end

  teardown do
    travel_back
  end

  test "self-service page is publicly accessible" do
    get self_service_url

    assert_response :success
  end

  test "creates a normal self-service ticket without a creator" do
    assert_difference "Ticket.count", 1 do
      post self_service_tickets_url, params: {
        ticket: {
          queue_service_id: queue_services(:admissions).id,
          assistance_type: ""
        }
      }
    end

    assert_redirected_to self_service_url

    ticket = Ticket.find_by!(
      ticket_number: "ADM-002",
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_equal "self_service", ticket.intake_source
    assert_equal "normal", ticket.priority
    assert_equal 6, ticket.priority_weight
    assert_equal "pending", ticket.status
    assert_nil ticket.assistance_type
    assert_nil ticket.created_by
    assert_equal 2, daily_sequences(:admissions_today).reload.current_number

    generated_ticket = flash[:generated_ticket]

    assert_equal "ADM-002", generated_ticket[:ticket_number]
    assert_equal "Admissions", generated_ticket[:service_name]
    assert_nil generated_ticket[:assistance_type]
  end

  test "creates a self-service ticket with senior assistance" do
    assert_difference "Ticket.count", 1 do
      post self_service_tickets_url, params: {
        ticket: {
          queue_service_id: queue_services(:finance).id,
          assistance_type: "senior"
        }
      }
    end

    assert_redirected_to self_service_url

    ticket = Ticket.find_by!(
      ticket_number: "FIN-002",
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_equal "self_service", ticket.intake_source
    assert_equal "senior", ticket.assistance_type
    assert_equal "senior", ticket.priority
    assert_equal 3, ticket.priority_weight
    assert_nil ticket.created_by

    generated_ticket = flash[:generated_ticket]

    assert_equal "FIN-002", generated_ticket[:ticket_number]
    assert_equal "Finance", generated_ticket[:service_name]
    assert_equal "senior", generated_ticket[:assistance_type]
  end

  test "rejects an invalid assistance type" do
    assert_no_difference "Ticket.count" do
      post self_service_tickets_url, params: {
        ticket: {
          queue_service_id: queue_services(:admissions).id,
          assistance_type: "invalid_assistance"
        }
      }
    end

    assert_redirected_to self_service_url
    assert_equal "Assistance type is invalid", flash[:alert]
  end

  test "rejects an inactive queue service" do
    queue_service = queue_services(:admissions)
    queue_service.update!(active: false)

    assert_no_difference "Ticket.count" do
      post self_service_tickets_url, params: {
        ticket: {
          queue_service_id: queue_service.id,
          assistance_type: ""
        }
      }
    end

    assert_redirected_to self_service_url
    assert_equal "Queue service is unavailable", flash[:alert]
  end
end
