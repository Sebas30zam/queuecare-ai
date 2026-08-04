require "test_helper"

class AiRecommendationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 15, 12, 0, 0)
  end

  teardown do
    travel_back
  end

  test "unauthenticated user is redirected" do
    get ai_recommendations_url

    assert_redirected_to login_url
  end

  test "admin can access AI recommendations" do
    login_as(users(:admin_user))

    get ai_recommendations_url

    assert_response :success
  end

  test "supervisor can access AI recommendations" do
    login_as(users(:supervisor_user))

    get ai_recommendations_url

    assert_response :success
  end

  test "receptionist cannot access AI recommendations" do
    login_as(users(:receptionist_user))

    get ai_recommendations_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "agent cannot access AI recommendations" do
    login_as(users(:agent_user))

    get ai_recommendations_url

    assert_redirected_to root_url
    assert_equal(
      "You are not authorized to access this page.",
      flash[:alert]
    )
  end

  test "renders AI recommendations index" do
    login_as(users(:admin_user))

    get ai_recommendations_url

    assert_equal(
      "ai_recommendations/index",
      inertia_page.fetch("component")
    )
  end

  test "includes current date prop" do
    login_as(users(:admin_user))

    get ai_recommendations_url

    assert_equal Date.current.iso8601, inertia_props.fetch("date")
  end

  test "includes operational recommendations prop" do
    login_as(users(:admin_user))

    get ai_recommendations_url

    recommendations =
      inertia_props.fetch("operational_recommendations")

    assert recommendations.key?("status")
    assert recommendations.key?("recommendations")
    assert recommendations.key?("next_holiday_alert")
    assert_kind_of Array, recommendations.fetch("recommendations")
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
