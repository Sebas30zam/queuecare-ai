require "test_helper"

class Analytics::HistoricalOperationalProfileServiceTest <
    ActiveSupport::TestCase
  setup do
    @queue_service = queue_services(:admissions)
  end

  test "returns the historical period and its operational metrics" do
    create_ticket(
      daily_sequence: 301,
      status: "attended",
      created_at: time_at(2040, 6, 1, 8),
      called_at: time_at(2040, 6, 1, 8, 10),
      started_at: time_at(2040, 6, 1, 8, 15),
      finished_at: time_at(2040, 6, 1, 8, 35)
    )
    create_ticket(
      daily_sequence: 302,
      status: "no_show",
      created_at: time_at(2040, 6, 14, 9)
    )
    create_ticket(
      daily_sequence: 303,
      status: "cancelled",
      created_at: time_at(2040, 6, 15, 8)
    )

    result = service(
      cutoff_date: Date.new(2040, 6, 15),
      period_days: 14
    ).call

    assert_equal(
      {
        start_date: "2040-06-01",
        end_date: "2040-06-14",
        period_days: 14
      },
      result[:period]
    )

    metrics = result[:metrics]

    assert_equal 2, metrics[:tickets_created]
    assert_equal 1, metrics[:tickets_attended]
    assert_equal 1, metrics[:tickets_no_show]
    assert_equal 0, metrics[:tickets_cancelled]
    assert_equal 0.14, metrics[:average_daily_demand]
    assert_equal 50.0, metrics[:no_show_rate_percentage]
    assert_equal 10.0, metrics[:average_wait_time_minutes]
    assert_equal 20.0, metrics[:average_attention_time_minutes]
  end

  test "accepts an ISO cutoff date and returns neutral metrics" do
    result = service(
      cutoff_date: "2041-02-01",
      period_days: 7
    ).call

    assert_equal "2041-01-25", result.dig(:period, :start_date)
    assert_equal "2041-01-31", result.dig(:period, :end_date)
    assert_equal 0, result.dig(:metrics, :tickets_created)
    assert_equal 0.0, result.dig(
      :metrics,
      :average_daily_demand
    )
  end

  test "rejects an invalid cutoff date" do
    error = assert_raises(ArgumentError) do
      service(
        cutoff_date: "not-a-date",
        period_days: 7
      )
    end

    assert_equal "cutoff_date must be a valid date", error.message
  end

  test "rejects a period without positive days" do
    error = assert_raises(ArgumentError) do
      service(
        cutoff_date: Date.new(2040, 6, 15),
        period_days: 0
      )
    end

    assert_equal(
      "period_days must be greater than zero",
      error.message
    )
  end

  private

  def service(cutoff_date:, period_days:)
    Analytics::HistoricalOperationalProfileService.new(
      cutoff_date:,
      period_days:
    )
  end

  def create_ticket(
    daily_sequence:,
    status:,
    created_at:,
    called_at: nil,
    started_at: nil,
    finished_at: nil
  )
    Ticket.create!(
      queue_service: @queue_service,
      ticket_number: format("ADM-P%03d", daily_sequence),
      sequence_date: created_at.to_date,
      daily_sequence:,
      priority: "normal",
      priority_weight: 6,
      status:,
      intake_source: "self_service",
      called_at:,
      started_at:,
      finished_at:,
      created_at:,
      updated_at: created_at
    )
  end

  def time_at(year, month, day, hour, minute = 0)
    Time.zone.local(year, month, day, hour, minute, 0)
  end
end
