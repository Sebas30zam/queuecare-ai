require "test_helper"

class Analytics::HistoricalMetricsCalculatorTest < ActiveSupport::TestCase
  test "calculates the historical operational metrics" do
    tickets = [
      build_ticket(
        status: "attended",
        created_at: time_at(1, 8),
        called_at: time_at(1, 8, 10),
        started_at: time_at(1, 8, 12),
        finished_at: time_at(1, 8, 32),
        survey_rating: 5
      ),
      build_ticket(
        status: "no_show",
        created_at: time_at(2, 8),
        called_at: time_at(2, 8, 20)
      ),
      build_ticket(
        status: "cancelled",
        created_at: time_at(2, 12)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(3, 9)
      ),
      build_ticket(
        status: "attended",
        created_at: time_at(3, 10),
        called_at: time_at(3, 10, 30),
        started_at: time_at(3, 10, 35),
        finished_at: time_at(3, 11, 15),
        survey_rating: 3
      )
    ]

    result = calculator(tickets:, period_days: 4).call

    assert_equal 4, result[:period_days]
    assert_equal 5, result[:tickets_created]
    assert_equal 2, result[:tickets_attended]
    assert_equal 1, result[:tickets_no_show]
    assert_equal 1, result[:tickets_cancelled]
    assert_equal 1.25, result[:average_daily_demand]
    assert_equal 20.0, result[:average_wait_time_minutes]
    assert_equal 30.0, result[:average_attention_time_minutes]
    assert_equal 20.0, result[:no_show_rate_percentage]
    assert_equal 20.0, result[:cancellation_rate_percentage]
    assert_equal 4.0, result[:average_satisfaction_rating]
    assert_equal 2, result[:survey_response_count]
  end

  test "calculates ticket distribution by service" do
    admissions = QueueService.new(
      name: "Admissions",
      code: "ADM"
    )
    finance = QueueService.new(
      name: "Finance",
      code: "FIN"
    )

    tickets = [
      build_ticket(
        status: "pending",
        created_at: time_at(1, 8),
        queue_service: admissions
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(1, 9),
        queue_service: admissions
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(2, 8),
        queue_service: admissions
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(2, 9),
        queue_service: finance
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(3, 8),
        queue_service: finance
      )
    ]

    result = calculator(tickets:, period_days: 3).call

    assert_equal(
      [
        {
          service_name: "Admissions",
          service_code: "ADM",
          tickets_created: 3,
          share_percentage: 60.0
        },
        {
          service_name: "Finance",
          service_code: "FIN",
          tickets_created: 2,
          share_percentage: 40.0
        }
      ],
      result[:service_distribution]
    )
  end

test "calculates ticket distribution by service window" do
  admissions = QueueService.new(
    name: "Admissions",
    code: "ADM"
  )
  window_one = ServiceWindow.new(
    name: "Window 1",
    code: "V1",
    queue_service: admissions
  )
  window_two = ServiceWindow.new(
    name: "Window 2",
    code: "V2",
    queue_service: admissions
  )

  tickets = [
    build_ticket(
      status: "pending",
      created_at: time_at(1, 8),
      queue_service: admissions,
      service_window: window_one
    ),
    build_ticket(
      status: "pending",
      created_at: time_at(1, 9),
      queue_service: admissions,
      service_window: window_one
    ),
    build_ticket(
      status: "pending",
      created_at: time_at(2, 8),
      queue_service: admissions,
      service_window: window_one
    ),
    build_ticket(
      status: "pending",
      created_at: time_at(2, 9),
      queue_service: admissions,
      service_window: window_two
    ),
    build_ticket(
      status: "pending",
      created_at: time_at(3, 8),
      queue_service: admissions,
      service_window: window_two
    ),
    build_ticket(
      status: "pending",
      created_at: time_at(3, 9),
      queue_service: admissions
    )
  ]

  result = calculator(tickets:, period_days: 3).call

  assert_equal(
    [
      {
        service_window_name: "Window 1",
        service_window_code: "V1",
        queue_service_name: "Admissions",
        queue_service_code: "ADM",
        tickets_assigned: 3,
        share_percentage: 60.0
      },
      {
        service_window_name: "Window 2",
        service_window_code: "V2",
        queue_service_name: "Admissions",
        queue_service_code: "ADM",
        tickets_assigned: 2,
        share_percentage: 40.0
      }
    ],
    result[:service_window_distribution]
  )
end

  test "calculates ticket distribution by creation hour" do
    tickets = [
      build_ticket(
        status: "pending",
        created_at: time_at(1, 8)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(1, 10)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(2, 8)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(2, 10, 30)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(3, 10)
      )
    ]

    result = calculator(tickets:, period_days: 3).call

    assert_equal(
      [
        {
          hour: 8,
          tickets_created: 2,
          share_percentage: 40.0
        },
        {
          hour: 10,
          tickets_created: 3,
          share_percentage: 60.0
        }
      ],
      result[:hourly_distribution]
    )
  end

  test "includes zero demand days in the daily average" do
    tickets = [
      build_ticket(
        status: "pending",
        created_at: time_at(1, 8)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(1, 9)
      )
    ]

    result = calculator(tickets:, period_days: 4).call

    assert_equal 0.5, result[:average_daily_demand]
  end

  test "builds historical activity including zero demand days" do
    tickets = [
      build_ticket(
        status: "attended",
        created_at: time_at(1, 8)
      ),
      build_ticket(
        status: "no_show",
        created_at: time_at(3, 9)
      )
    ]

    result = calculator(
      tickets:,
      period_days: 4,
      start_date: Date.new(2026, 6, 1)
    ).call

    assert_equal(
      [
        {
          status: "pending",
          tickets: 0,
          share_percentage: 0.0
        },
        {
          status: "called",
          tickets: 0,
          share_percentage: 0.0
        },
        {
          status: "in_attention",
          tickets: 0,
          share_percentage: 0.0
        },
        {
          status: "attended",
          tickets: 1,
          share_percentage: 50.0
        },
        {
          status: "no_show",
          tickets: 1,
          share_percentage: 50.0
        },
        {
          status: "cancelled",
          tickets: 0,
          share_percentage: 0.0
        }
      ],
      result[:status_distribution]
    )

    assert_equal(
      %w[
        2026-06-01
        2026-06-02
        2026-06-03
        2026-06-04
      ],
      result[:daily_activity].pluck(:date)
    )

    assert_equal(
      %w[monday tuesday wednesday thursday],
      result[:daily_activity].pluck(:weekday)
    )

    assert_equal(
      [ 1, 0, 1, 0 ],
      result[:daily_activity].pluck(:tickets_created)
    )

    assert_equal(
      {
        "pending" => 0,
        "called" => 0,
        "in_attention" => 0,
        "attended" => 1,
        "no_show" => 0,
        "cancelled" => 0
      },
      result.dig(:daily_activity, 0, :status_counts)
    )

    assert_equal(
      {
        "pending" => 0,
        "called" => 0,
        "in_attention" => 0,
        "attended" => 0,
        "no_show" => 0,
        "cancelled" => 0
      },
      result.dig(:daily_activity, 1, :status_counts)
    )

    assert_equal(
      %w[monday tuesday wednesday thursday],
      result[:weekday_activity].pluck(:weekday)
    )

    assert_equal(
      [ 1, 1, 1, 1 ],
      result[:weekday_activity].pluck(:days_observed)
    )

    assert_equal(
      [ 1, 0, 1, 0 ],
      result[:weekday_activity].pluck(:tickets_created)
    )
  end

  test "aggregates repeated weekdays across the historical period" do
    tickets = [
      build_ticket(
        status: "pending",
        created_at: time_at(1, 8)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(1, 9)
      ),
      build_ticket(
        status: "pending",
        created_at: time_at(8, 8)
      )
    ]

    result = calculator(
      tickets:,
      period_days: 8,
      start_date: Date.new(2026, 6, 1)
    ).call

    monday = result[:weekday_activity].find do |activity|
      activity[:weekday] == "monday"
    end

    assert_equal 2, monday[:days_observed]
    assert_equal 3, monday[:tickets_created]
    assert_equal 1.5, monday[:average_daily_demand]
    assert_equal 3, monday.dig(:status_counts, "pending")
  end

  test "ignores incomplete durations and unsubmitted surveys" do
    incomplete_ticket = build_ticket(
      status: "in_attention",
      created_at: time_at(1, 8),
      started_at: time_at(1, 8, 15),
      survey_rating: 2,
      survey_submitted: false
    )

    result = calculator(
      tickets: [ incomplete_ticket ],
      period_days: 1
    ).call

    assert_nil result[:average_wait_time_minutes]
    assert_nil result[:average_attention_time_minutes]
    assert_nil result[:average_satisfaction_rating]
    assert_equal 0, result[:survey_response_count]
  end

  test "returns neutral values when there are no tickets" do
    result = calculator(tickets: [], period_days: 7).call

    assert_equal 7, result[:period_days]
    assert_equal 0, result[:tickets_created]
    assert_equal 0, result[:tickets_attended]
    assert_equal 0, result[:tickets_no_show]
    assert_equal 0, result[:tickets_cancelled]
    assert_equal 0.0, result[:average_daily_demand]
    assert_equal 0.0, result[:no_show_rate_percentage]
    assert_equal 0.0, result[:cancellation_rate_percentage]
    assert_nil result[:average_wait_time_minutes]
    assert_nil result[:average_attention_time_minutes]
    assert_nil result[:average_satisfaction_rating]
    assert_equal 0, result[:survey_response_count]
    assert_empty result[:service_distribution]
    assert_empty result[:hourly_distribution]
    assert_empty result[:service_window_distribution]
  end

  test "rejects a period without positive days" do
    error = assert_raises(ArgumentError) do
      calculator(tickets: [], period_days: 0)
    end

    assert_equal(
      "period_days must be greater than zero",
      error.message
    )
  end

  private

  def calculator(tickets:, period_days:, start_date: nil)
    Analytics::HistoricalMetricsCalculator.new(
      tickets:,
      period_days:,
      start_date:
    )
  end

  def build_ticket(
    status:,
    created_at:,
    called_at: nil,
    started_at: nil,
    finished_at: nil,
    survey_rating: nil,
    survey_submitted: true,
    queue_service: nil,
    service_window: nil
  )
    ticket = Ticket.new(
      queue_service:,
      service_window:,
      status:,
      created_at:,
      called_at:,
      started_at:,
      finished_at:
    )

    if survey_rating
      ticket.build_satisfaction_survey(
        rating: survey_rating,
        submitted_at: survey_submitted ? created_at : nil
      )
    end

    ticket
  end

  def time_at(day, hour, minute = 0)
    Time.zone.local(2026, 6, day, hour, minute, 0)
  end
end
