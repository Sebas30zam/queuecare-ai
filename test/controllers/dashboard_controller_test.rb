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

  test "receptionist cannot access dashboard" do
    login_as(users(:receptionist_user))

    get dashboard_url

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

  test "renders dashboard index" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_equal "dashboard/index", inertia_page.fetch("component")
  end

  test "includes date prop" do
    login_as(users(:admin_user))

    get dashboard_url

    assert_equal Date.current.iso8601, inertia_props.fetch("date")
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
