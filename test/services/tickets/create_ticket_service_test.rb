require "test_helper"

class Tickets::CreateTicketServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 10, 0, 0)
  end

  teardown do
    travel_back
  end

  test "creates a normal self-service ticket without a creator" do
    result = nil

    assert_difference "Ticket.count", 1 do
      result = create_ticket(
        queue_service: queue_services(:admissions),
        intake_source: "self_service"
      )
    end

    assert result.success?

    ticket = result.ticket

    assert_equal "ADM-002", ticket.ticket_number
    assert_equal "normal", ticket.priority
    assert_equal 6, ticket.priority_weight
    assert_equal "pending", ticket.status
    assert_equal "self_service", ticket.intake_source
    assert_nil ticket.assistance_type
    assert_nil ticket.created_by
    assert_equal 2, daily_sequences(:admissions_today).reload.current_number
  end

  test "maps self-service assistance to its priority and weight" do
    result = create_ticket(
      queue_service: queue_services(:finance),
      intake_source: "self_service",
      assistance_type: "senior"
    )

    assert result.success?

    ticket = result.ticket

    assert_equal "FIN-002", ticket.ticket_number
    assert_equal "senior", ticket.assistance_type
    assert_equal "senior", ticket.priority
    assert_equal 3, ticket.priority_weight
    assert_nil ticket.created_by
  end

  test "records the creator for assisted intake" do
    receptionist = users(:receptionist_user)

    result = create_ticket(
      queue_service: queue_services(:admissions),
      intake_source: "assisted",
      current_user: receptionist
    )

    assert result.success?
    assert_equal "assisted", result.ticket.intake_source
    assert_equal receptionist, result.ticket.created_by
    assert_equal "normal", result.ticket.priority
  end

  test "rejects assisted intake without a current user" do
    assert_no_difference "Ticket.count" do
      result = create_ticket(
        queue_service: queue_services(:admissions),
        intake_source: "assisted",
        current_user: nil
      )

      assert_not result.success?
      assert_includes result.errors,
                      "Current user is required for assisted intake"
    end
  end

  test "rejects an invalid assistance type" do
    assert_no_difference "Ticket.count" do
      result = create_ticket(
        queue_service: queue_services(:admissions),
        intake_source: "self_service",
        assistance_type: "invalid_assistance"
      )

      assert_not result.success?
      assert_includes result.errors, "Assistance type is invalid"
    end
  end

  test "rejects an inactive queue service" do
    queue_service = queue_services(:admissions)
    queue_service.update!(active: false)

    assert_no_difference "Ticket.count" do
      result = create_ticket(
        queue_service: queue_service,
        intake_source: "self_service"
      )

      assert_not result.success?
      assert_includes result.errors, "Queue service is unavailable"
    end
  end

  test "increments consecutive ticket numbers for the same service" do
    first_result = create_ticket(
      queue_service: queue_services(:admissions),
      intake_source: "self_service"
    )

    second_result = create_ticket(
      queue_service: queue_services(:admissions),
      intake_source: "self_service"
    )

    assert first_result.success?
    assert second_result.success?
    assert_equal "ADM-002", first_result.ticket.ticket_number
    assert_equal "ADM-003", second_result.ticket.ticket_number
    assert_equal 3, daily_sequences(:admissions_today).reload.current_number
  end

  private

  def create_ticket(
    queue_service:,
    intake_source:,
    assistance_type: "",
    current_user: nil
  )
    Tickets::CreateTicketService.new(
      current_user: current_user,
      params: {
        queue_service_id: queue_service.id,
        intake_source: intake_source,
        assistance_type: assistance_type
      }
    ).call
  end
end
