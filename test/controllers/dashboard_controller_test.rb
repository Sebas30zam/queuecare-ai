require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 15, 12, 0, 0)
  end

  teardown do
    travel_back
  end

  test "unauthenticated user is redirected" do
    get dashboard_url

    assert_redirected_to login_url
  end

  test "admin can access dashboard" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_response :success
  end

  test "supervisor can access dashboard" do
    login_as(users(:supervisor_user))

    get dashboard_url

    assert_response :success
  end

  test "supervisor can access dashboard with date range" do
    login_as(users(:supervisor_user))

    get dashboard_url(
      start_date: "2026-06-10",
      end_date: "2026-06-15"
    )

    assert_response :success
    assert_equal "2026-06-10", inertia_props.fetch("start_date")
    assert_equal "2026-06-15", inertia_props.fetch("end_date")
  end

  test "receptionist cannot access dashboard" do
    login_as(users(:receptionist_user))

    get dashboard_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "receptionist cannot access dashboard with date range" do
    login_as(users(:receptionist_user))

    get dashboard_url(
      start_date: "2026-06-10",
      end_date: "2026-06-15"
    )

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "agent cannot access dashboard" do
    login_as(users(:agent_user))

    get dashboard_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "agent cannot access dashboard with date range" do
    login_as(users(:agent_user))

    get dashboard_url(
      start_date: "2026-06-10",
      end_date: "2026-06-15"
    )

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "renders dashboard index" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_equal "dashboard/index", inertia_page.fetch("component")
  end

  test "uses current date for both range dates by default" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_equal Date.current.iso8601, inertia_props.fetch("start_date")
    assert_equal Date.current.iso8601, inertia_props.fetch("end_date")
  end

  test "uses selected date range when valid params are provided" do
    login_as(users(:admin_user))

    get dashboard_url(
      start_date: "2026-06-10",
      end_date: "2026-06-15"
    )

    assert_response :success
    assert_equal "2026-06-10", inertia_props.fetch("start_date")
    assert_equal "2026-06-15", inertia_props.fetch("end_date")
  end

  test "supports a single day when start and end date match" do
    login_as(users(:admin_user))

    get dashboard_url(
      start_date: "2026-06-10",
      end_date: "2026-06-10"
    )

    assert_response :success
    assert_equal "2026-06-10", inertia_props.fetch("start_date")
    assert_equal "2026-06-10", inertia_props.fetch("end_date")
  end

  test "handles invalid date range safely" do
    login_as(users(:admin_user))

    get dashboard_url(
      start_date: "invalid-date",
      end_date: "2026-06-15"
    )

    assert_response :success
    assert_equal Date.current.iso8601, inertia_props.fetch("start_date")
    assert_equal Date.current.iso8601, inertia_props.fetch("end_date")
  end

  test "handles reversed date range safely" do
    login_as(users(:admin_user))

    get dashboard_url(
      start_date: "2026-06-15",
      end_date: "2026-06-10"
    )

    assert_response :success
    assert_equal Date.current.iso8601, inertia_props.fetch("start_date")
    assert_equal Date.current.iso8601, inertia_props.fetch("end_date")
  end

  test "returns empty metrics for range without tickets" do
    login_as(users(:admin_user))

    get dashboard_url(
      start_date: "2025-01-01",
      end_date: "2025-01-05"
    )

    assert_response :success

    summary = inertia_props.fetch("summary")

    assert_equal 0, summary.fetch("tickets_created")
    assert_equal 0, summary.fetch("tickets_attended")
    assert_equal 0, summary.fetch("tickets_pending")
    assert_equal 0, summary.fetch("tickets_no_show")
    assert_equal 0, summary.fetch("tickets_cancelled")
  end

  test "includes summary prop" do
    login_as(users(:admin_user))

    get dashboard_url

    summary = inertia_props.fetch("summary")

    assert summary.key?("tickets_created")
    assert summary.key?("tickets_attended")
    assert summary.key?("tickets_pending")
    assert summary.key?("tickets_no_show")
    assert summary.key?("tickets_cancelled")
    assert summary.key?("average_wait_time_minutes")
    assert summary.key?("average_attention_time_minutes")
    assert summary.key?("average_satisfaction_rating")
    assert summary.key?("survey_response_count")
  end

  test "includes services prop" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_kind_of Array, inertia_props.fetch("services")
  end

  test "includes hourly activity prop" do
    login_as(users(:admin_user))

    get dashboard_url

    hourly_activity = inertia_props.fetch("hourly_activity")

    assert_kind_of Array, hourly_activity
    assert_empty hourly_activity
  end

  test "includes status distribution prop" do
    login_as(users(:admin_user))

    get dashboard_url

    status_distribution = inertia_props.fetch("status_distribution")

    assert_kind_of Array, status_distribution
    assert status_distribution.any? { |item| item["status"] == "pending" }
    assert status_distribution.all? { |item| item.key?("count") }
  end

  test "includes service windows prop" do
    login_as(users(:admin_user))

    get dashboard_url

    service_windows = inertia_props.fetch("service_windows")

    assert_kind_of Array, service_windows

    if service_windows.any?
      first_window = service_windows.first

      assert first_window.key?("code")
      assert first_window.key?("tickets_created")
      assert first_window.key?("ticket_share_percentage")
      assert first_window.key?("queue_service")
    end
  end

  test "includes critical services prop" do
    login_as(users(:admin_user))

    get dashboard_url

    critical_services = inertia_props.fetch("critical_services")

    assert_kind_of Array, critical_services

    if critical_services.any?
      first_service = critical_services.first

      assert first_service.key?("operational_status")
      assert first_service.key?("average_wait_time_minutes")
    end
  end

  test "includes insights prop" do
    login_as(users(:admin_user))

    get dashboard_url

    insights = inertia_props.fetch("insights")

    assert insights.key?("peak_hour")
    assert insights.key?("highest_wait_service")
  end

  test "includes operational recommendations prop" do
    login_as(users(:admin_user))

    get dashboard_url

    operational_recommendations =
      inertia_props.fetch("operational_recommendations")

    assert operational_recommendations.key?("status")
    assert operational_recommendations.key?("next_holiday_alert")
    assert_kind_of(
      Array,
      operational_recommendations.fetch("recommendations")
    )
  end

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end

  def inertia_page
    page_element = Nokogiri::HTML(response.body).at_css(
      'script[data-page="app"]'
    )

    raise "Inertia page data was not found" unless page_element

    JSON.parse(page_element.text)
  end

  def inertia_props
    inertia_page.fetch("props")
  end
end
