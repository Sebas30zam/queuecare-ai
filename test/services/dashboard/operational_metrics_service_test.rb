require "test_helper"

class Dashboard::OperationalMetricsServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 15, 12, 0, 0)

    @admissions = queue_services(:admissions)
    @finance = queue_services(:finance)
  end

  teardown do
    travel_back
  end

  test "returns zero metrics when there are no tickets" do
    Ticket.delete_all

    result = service.call

    assert_equal 0, result[:summary][:tickets_created]
    assert_equal 0, result[:summary][:tickets_attended]
    assert_equal 0, result[:summary][:tickets_pending]
    assert_equal 0, result[:summary][:tickets_no_show]
    assert_equal 0, result[:summary][:tickets_cancelled]
    assert_nil result[:summary][:average_wait_time_minutes]
    assert_nil result[:summary][:average_attention_time_minutes]
    assert_nil result[:summary][:average_satisfaction_rating]
    assert_equal 0, result[:summary][:survey_response_count]
  end

  test "counts tickets created today" do
    create_ticket(status: "pending", daily_sequence: 101)
    create_ticket(status: "called", daily_sequence: 102)

    assert_equal 2, service.call[:summary][:tickets_created]
  end

  test "counts attended tickets" do
    create_ticket(status: "attended", daily_sequence: 103)

    assert_equal 1, service.call[:summary][:tickets_attended]
  end

  test "counts pending tickets" do
    create_ticket(status: "pending", daily_sequence: 104)

    assert_equal 1, service.call[:summary][:tickets_pending]
  end

  test "counts no show tickets" do
    create_ticket(status: "no_show", daily_sequence: 105)

    assert_equal 1, service.call[:summary][:tickets_no_show]
  end

  test "counts cancelled tickets" do
    create_ticket(status: "cancelled", daily_sequence: 106)

    assert_equal 1, service.call[:summary][:tickets_cancelled]
  end

  test "calculates average wait time" do
    create_ticket(
      status: "called",
      daily_sequence: 107,
      created_at: 30.minutes.ago,
      called_at: 20.minutes.ago
    )

    create_ticket(
      status: "attended",
      daily_sequence: 108,
      created_at: 50.minutes.ago,
      called_at: 30.minutes.ago
    )

    assert_equal 15.0, service.call[:summary][:average_wait_time_minutes]
  end

  test "calculates average attention time" do
    create_ticket(
      status: "attended",
      daily_sequence: 109,
      started_at: 30.minutes.ago,
      finished_at: 20.minutes.ago
    )

    create_ticket(
      status: "attended",
      daily_sequence: 110,
      started_at: 40.minutes.ago,
      finished_at: 20.minutes.ago
    )

    assert_equal(
      15.0,
      service.call[:summary][:average_attention_time_minutes]
    )
  end

  test "ignores tickets with missing timestamps in averages" do
    create_ticket(
      status: "called",
      daily_sequence: 111,
      created_at: 20.minutes.ago,
      called_at: 10.minutes.ago
    )

    create_ticket(
      status: "pending",
      daily_sequence: 112,
      called_at: nil
    )

    create_ticket(
      status: "attended",
      daily_sequence: 113,
      started_at: 15.minutes.ago,
      finished_at: 5.minutes.ago
    )

    create_ticket(
      status: "in_attention",
      daily_sequence: 114,
      started_at: 5.minutes.ago,
      finished_at: nil
    )

    summary = service.call[:summary]

    assert_equal 10.0, summary[:average_wait_time_minutes]
    assert_equal 10.0, summary[:average_attention_time_minutes]
  end

  test "calculates average satisfaction rating" do
    first_ticket = create_ticket(
      status: "attended",
      daily_sequence: 115,
      started_at: 30.minutes.ago,
      finished_at: 20.minutes.ago
    )

    second_ticket = create_ticket(
      status: "attended",
      daily_sequence: 116,
      started_at: 20.minutes.ago,
      finished_at: 10.minutes.ago
    )

    create_survey(ticket: first_ticket, rating: 4)
    create_survey(ticket: second_ticket, rating: 5)

    assert_equal(
      4.5,
      service.call[:summary][:average_satisfaction_rating]
    )
  end

  test "counts survey responses" do
    ticket = create_ticket(
      status: "attended",
      daily_sequence: 117,
      started_at: 20.minutes.ago,
      finished_at: 10.minutes.ago
    )

    create_survey(ticket: ticket, rating: 5)

    assert_equal 1, service.call[:summary][:survey_response_count]
  end

  test "groups metrics by queue service" do
    create_ticket(
      queue_service: @admissions,
      status: "pending",
      daily_sequence: 118
    )

    create_ticket(
      queue_service: @finance,
      status: "attended",
      daily_sequence: 119,
      started_at: 20.minutes.ago,
      finished_at: 10.minutes.ago
    )

    services = service.call[:services]

    admissions_metrics = services.find { |item| item[:id] == @admissions.id }
    finance_metrics = services.find { |item| item[:id] == @finance.id }

    assert_equal 1, admissions_metrics[:tickets_created]
    assert_equal 1, admissions_metrics[:tickets_pending]
    assert_equal 0, admissions_metrics[:tickets_attended]

    assert_equal 1, finance_metrics[:tickets_created]
    assert_equal 1, finance_metrics[:tickets_attended]
    assert_equal 0, finance_metrics[:tickets_pending]
  end

  test "excludes tickets created outside the selected date" do
    create_ticket(
      status: "pending",
      daily_sequence: 120,
      created_at: 1.day.ago
    )

    create_ticket(
      status: "pending",
      daily_sequence: 121,
      created_at: Time.current
    )

    assert_equal 1, service.call[:summary][:tickets_created]
  end

  test "keeps active services with zero activity" do
    Ticket.delete_all

    services = service.call[:services]

    admissions_metrics = services.find { |item| item[:id] == @admissions.id }
    finance_metrics = services.find { |item| item[:id] == @finance.id }

    assert_not_nil admissions_metrics
    assert_not_nil finance_metrics
    assert_equal 0, admissions_metrics[:tickets_created]
    assert_equal 0, finance_metrics[:tickets_created]
  end

  test "groups created tickets by hour" do
    create_ticket(
      status: "pending",
      daily_sequence: 122,
      created_at: Time.zone.local(2026, 6, 15, 8, 5, 0)
    )

    create_ticket(
      status: "pending",
      daily_sequence: 123,
      created_at: Time.zone.local(2026, 6, 15, 10, 15, 0)
    )

    create_ticket(
      status: "pending",
      daily_sequence: 124,
      created_at: Time.zone.local(2026, 6, 15, 10, 45, 0)
    )

    hourly_activity = service.call[:hourly_activity]

    assert_equal 3, hourly_activity.size
    assert_equal(
      1,
      hourly_activity.find { |item| item[:hour] == 8 }[:tickets_created]
    )
    assert_equal(
      2,
      hourly_activity.find { |item| item[:hour] == 10 }[:tickets_created]
    )
    assert_equal(
      0,
      hourly_activity.find { |item| item[:hour] == 9 }[:tickets_created]
    )
  end

  test "returns ticket status distribution" do
    create_ticket(status: "pending", daily_sequence: 125)
    create_ticket(status: "attended", daily_sequence: 126)
    create_ticket(status: "attended", daily_sequence: 127)
    create_ticket(status: "no_show", daily_sequence: 128)

    distribution = service.call[:status_distribution]

    pending = distribution.find { |item| item[:status] == "pending" }
    attended = distribution.find { |item| item[:status] == "attended" }
    no_show = distribution.find { |item| item[:status] == "no_show" }

    assert_equal 1, pending[:count]
    assert_equal 2, attended[:count]
    assert_equal 1, no_show[:count]
  end

  test "calculates ticket share by service window" do
    create_ticket(
      queue_service: @admissions,
      service_window: service_windows(:window_one),
      status: "pending",
      daily_sequence: 129
    )

    create_ticket(
      queue_service: @admissions,
      service_window: service_windows(:window_one),
      status: "attended",
      daily_sequence: 130
    )

    create_ticket(
      queue_service: @finance,
      service_window: service_windows(:window_two),
      status: "pending",
      daily_sequence: 131
    )

    windows = service.call[:service_windows]

    first_window = windows.find do |item|
      item[:id] == service_windows(:window_one).id
    end

    second_window = windows.find do |item|
      item[:id] == service_windows(:window_two).id
    end

    assert_equal 2, first_window[:tickets_created]
    assert_equal 66.67, first_window[:ticket_share_percentage]
    assert_equal 1, second_window[:tickets_created]
    assert_equal 33.33, second_window[:ticket_share_percentage]
  end

  test "returns operational insights from real ticket activity" do
    create_ticket(
      queue_service: @admissions,
      status: "called",
      daily_sequence: 132,
      created_at: Time.zone.local(2026, 6, 15, 8, 0, 0),
      called_at: Time.zone.local(2026, 6, 15, 8, 10, 0)
    )

    create_ticket(
      queue_service: @finance,
      status: "called",
      daily_sequence: 133,
      created_at: Time.zone.local(2026, 6, 15, 10, 0, 0),
      called_at: Time.zone.local(2026, 6, 15, 10, 30, 0)
    )

    create_ticket(
      queue_service: @finance,
      status: "pending",
      daily_sequence: 134,
      created_at: Time.zone.local(2026, 6, 15, 10, 30, 0)
    )

    result = service.call

    assert_equal(
      @finance.id,
      result[:insights][:highest_wait_service][:id]
    )

    assert_equal 10, result[:insights][:peak_hour][:hour]
    assert_equal 2, result[:insights][:peak_hour][:tickets_created]
  end

  test "derives service statuses from the daily average" do
    create_ticket(
      queue_service: @admissions,
      status: "called",
      daily_sequence: 135,
      created_at: 20.minutes.ago,
      called_at: 10.minutes.ago
    )

    create_ticket(
      queue_service: @finance,
      status: "called",
      daily_sequence: 136,
      created_at: 40.minutes.ago,
      called_at: 10.minutes.ago
    )

    critical_services = service.call[:critical_services]

    admissions = critical_services.find do |item|
      item[:id] == @admissions.id
    end

    finance = critical_services.find do |item|
      item[:id] == @finance.id
    end

    assert_equal "normal", admissions[:operational_status]
    assert_equal "critical", finance[:operational_status]
    assert_equal @finance.id, critical_services.first[:id]
  end

  private

  def service
    Dashboard::OperationalMetricsService.new(date: Date.current)
  end

  def create_ticket(
    queue_service: @admissions,
    status:,
    daily_sequence:,
    created_at: Time.current,
    **timestamps
  )
    Ticket.create!(
      queue_service: queue_service,
      ticket_number: format("%s-%03d", queue_service.code, daily_sequence),
      sequence_date: Date.current,
      daily_sequence: daily_sequence,
      priority: "normal",
      priority_weight: 6,
      status: status,
      intake_source: "self_service",
      created_at: created_at,
      updated_at: created_at,
      **timestamps
    )
  end

  def create_survey(ticket:, rating:)
    SatisfactionSurvey.create!(
      ticket: ticket,
      rating: rating,
      comment: "Dashboard test survey",
      submitted_at: Time.current
    )
  end
end
