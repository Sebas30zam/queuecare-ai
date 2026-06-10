require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "self-service ticket is valid without a creator" do
    ticket = build_ticket(
      intake_source: "self_service",
      created_by: nil
    )

    assert ticket.valid?
  end

  test "assisted ticket requires a creator" do
    ticket = build_ticket(
      intake_source: "assisted",
      created_by: nil
    )

    assert_not ticket.valid?
    assert_includes ticket.errors[:created_by],
                    "is required for assisted intake"
  end

  test "assisted ticket is valid with a creator" do
    ticket = build_ticket(
      intake_source: "assisted",
      created_by: users(:receptionist_user)
    )

    assert ticket.valid?
  end

  test "rejects invalid status priority intake source and assistance type" do
    ticket = build_ticket(
      status: "invalid_status",
      priority: "invalid_priority",
      intake_source: "invalid_source",
      assistance_type: "invalid_assistance"
    )

    assert_not ticket.valid?
    assert ticket.errors[:status].any?
    assert ticket.errors[:priority].any?
    assert ticket.errors[:intake_source].any?
    assert ticket.errors[:assistance_type].any?
  end

  test "ticket number must be unique within the same sequence date" do
    ticket = build_ticket(
      ticket_number: "ADM-001",
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_not ticket.valid?
    assert ticket.errors[:ticket_number].any?
  end

  test "ticket number may repeat on a different sequence date" do
    ticket = build_ticket(
      ticket_number: "ADM-001",
      sequence_date: Date.new(2026, 6, 10)
    )

    assert ticket.valid?
  end

  test "ticket fixtures are valid" do
    assert tickets(:self_service_ticket).valid?
    assert tickets(:assisted_senior_ticket).valid?
  end

  private

  def build_ticket(attributes = {})
    Ticket.new(
      {
        queue_service: queue_services(:admissions),
        ticket_number: "ADM-900",
        sequence_date: Date.new(2026, 6, 10),
        daily_sequence: 900,
        priority: "normal",
        priority_weight: 6,
        status: "pending",
        intake_source: "self_service",
        assistance_type: nil,
        created_by: nil
      }.merge(attributes)
    )
  end
end
