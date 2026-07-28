require "test_helper"

class Analytics::NextHolidayAlertServiceTest <
    ActiveSupport::TestCase
  setup do
    @date = Date.new(2026, 7, 28)
    @next_holiday = {
      date: "2026-08-02",
      names: [ "Feast of Our Lady of the Angels" ],
      days_away: 5
    }
  end

  test "returns nil when there is no next holiday" do
    result = build_service(
      calendar_context: { next_holiday: nil }
    ).call

    assert_nil result
  end

  test "returns next holiday metadata and staffing date" do
    result = build_service.call

    assert_equal "2026-08-02", result[:date]
    assert_equal(
      [ "Feast of Our Lady of the Angels" ],
      result[:names]
    )
    assert_equal 5, result[:days_away]
    assert_equal "2026-08-03", result[:recommended_staffing_date]
  end

  test "reports insufficient historical data without inventing a percentage" do
    result = build_service.call

    assert_not result[:historical_data_available]
    assert_nil result[:demand_change_percentage]
    assert_equal(
      {
        post_holiday_days: 0,
        baseline_days: 0
      },
      result[:historical_sample]
    )
  end

  test "calculates historical post-holiday demand change" do
    holiday_dates = [
      Date.new(2026, 6, 1),
      Date.new(2026, 6, 15)
    ]

    post_holiday_dates = [
      Date.new(2026, 6, 2),
      Date.new(2026, 6, 16)
    ]

    baseline_dates = [
      Date.new(2026, 6, 3),
      Date.new(2026, 6, 10),
      Date.new(2026, 6, 17),
      Date.new(2026, 6, 24),
      Date.new(2026, 7, 1)
    ]

    post_holiday_dates.each do |ticket_date|
      create_tickets(date: ticket_date, count: 3)
    end

    baseline_dates.each do |ticket_date|
      create_tickets(date: ticket_date, count: 2)
    end

    result = build_service(
      holiday_dates: holiday_dates,
      tickets_scope: Ticket.where(
        "ticket_number LIKE ?",
        "NHA-%"
      )
    ).call

    assert result[:historical_data_available]
    assert_equal 50, result[:demand_change_percentage]
    assert_equal(
      {
        post_holiday_days: 2,
        baseline_days: 5
      },
      result[:historical_sample]
    )
  end

  private

  def build_service(
    calendar_context: { next_holiday: @next_holiday },
    holiday_dates: [],
    tickets_scope: Ticket.none
  )
    Analytics::NextHolidayAlertService.new(
      date: @date,
      calendar_context:,
      holiday_query: FakeHolidayQuery.new(holiday_dates),
      tickets_scope:
    )
  end

  def create_tickets(date:, count:)
    count.times do |index|
      Ticket.create!(
        queue_service: queue_services(:admissions),
        ticket_number:
          "NHA-#{date.strftime("%Y%m%d")}-#{index + 1}",
        sequence_date: date,
        daily_sequence: index + 1,
        priority: "normal",
        priority_weight: 6,
        status: "pending",
        intake_source: "self_service",
        created_at: date.in_time_zone.change(hour: 8),
        updated_at: date.in_time_zone.change(hour: 8)
      )
    end
  end

  FakeHoliday = Struct.new(:date)

  class FakeHolidayQuery
    def initialize(holiday_dates)
      @holiday_dates = holiday_dates
    end

    def between(start_date:, end_date:)
      holiday_dates
        .select { |date| date.between?(start_date, end_date) }
        .map { |date| FakeHoliday.new(date) }
    end

    def holiday?(date:)
      holiday_dates.include?(date)
    end

    private

    attr_reader :holiday_dates
  end
end
