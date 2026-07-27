require "test_helper"

class Analytics::HistoricalTicketsQueryTest < ActiveSupport::TestCase
  setup do
    @queue_service = queue_services(:admissions)
    @start_date = Date.new(2026, 6, 1)
    @cutoff_date = Date.new(2026, 6, 15)
  end

  test "returns tickets inside the historical period" do
    first_ticket = create_ticket(
      daily_sequence: 201,
      created_at: Time.zone.local(2026, 6, 1, 8, 0, 0)
    )
    second_ticket = create_ticket(
      daily_sequence: 202,
      created_at: Time.zone.local(2026, 6, 14, 16, 0, 0)
    )

    result = query.call

    assert_includes result, first_ticket
    assert_includes result, second_ticket
  end

  test "excludes tickets before the historical period" do
    excluded_ticket = create_ticket(
      daily_sequence: 203,
      created_at: Time.zone.local(2026, 5, 31, 23, 59, 59)
    )

    assert_not_includes query.call, excluded_ticket
  end

  test "excludes the cutoff date and future tickets" do
    cutoff_ticket = create_ticket(
      daily_sequence: 204,
      created_at: Time.zone.local(2026, 6, 15, 0, 0, 0)
    )
    future_ticket = create_ticket(
      daily_sequence: 205,
      created_at: Time.zone.local(2026, 6, 16, 8, 0, 0)
    )

    result = query.call

    assert_not_includes result, cutoff_ticket
    assert_not_includes result, future_ticket
  end

  test "returns tickets in chronological order" do
    later_ticket = create_ticket(
      daily_sequence: 206,
      created_at: Time.zone.local(2026, 6, 10, 10, 0, 0)
    )
    earlier_ticket = create_ticket(
      daily_sequence: 207,
      created_at: Time.zone.local(2026, 6, 5, 10, 0, 0)
    )

    result_ids = query.call.pluck(:id)

    assert_operator(
      result_ids.index(earlier_ticket.id),
      :<,
      result_ids.index(later_ticket.id)
    )
  end

  test "rejects a historical period without previous dates" do
    error = assert_raises(ArgumentError) do
      described_class.new(
        start_date: @cutoff_date,
        cutoff_date: @cutoff_date
      )
    end

    assert_equal(
      "start_date must be before cutoff_date",
      error.message
    )
  end

  private

  def described_class
    Analytics::HistoricalTicketsQuery
  end

  def query
    described_class.new(
      start_date: @start_date,
      cutoff_date: @cutoff_date
    )
  end

  def create_ticket(daily_sequence:, created_at:)
    Ticket.create!(
      queue_service: @queue_service,
      ticket_number: format("ADM-H%03d", daily_sequence),
      sequence_date: created_at.to_date,
      daily_sequence: daily_sequence,
      priority: "normal",
      priority_weight: 6,
      status: "pending",
      intake_source: "self_service",
      created_at:,
      updated_at: created_at
    )
  end
end
