require "test_helper"

class SatisfactionSurveysControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 22, 10, 30, 0)

    @ticket = tickets(:self_service_ticket)
    @ticket.update!(
      service_window: service_windows(:window_one),
      status: "attended",
      called_at: 20.minutes.ago,
      started_at: 15.minutes.ago,
      finished_at: 5.minutes.ago
    )
  end

  teardown do
    travel_back
  end

  test "survey page is accessible without login" do
    get survey_url

    assert_response :success
  end

  test "attended ticket can open survey" do
    get survey_url

    assert_response :success
    assert_equal "satisfaction-surveys/show",
                 inertia_page.fetch("component")

    ticket_props = inertia_page.fetch("props").fetch("ticket")

    assert_equal @ticket.ticket_number,
                 ticket_props.fetch("ticket_number")
    assert_equal "attended", ticket_props.fetch("status")
    assert_equal "Admissions",
                 ticket_props.fetch("queue_service").fetch("name")
    assert_equal "Window 1",
                 ticket_props.fetch("service_window").fetch("name")
  end

  test "pending ticket cannot open survey" do
    @ticket.update!(
      status: "pending",
      finished_at: nil
    )

    get survey_url

    assert_response :not_found
  end

  test "no show ticket cannot open survey" do
    @ticket.update!(
      status: "no_show",
      finished_at: nil,
      no_show_at: Time.current
    )

    get survey_url

    assert_response :not_found
  end

  test "invalid token is handled safely" do
    get satisfaction_survey_url(
      survey_token: "invalid-survey-token"
    )

    assert_response :not_found
  end

  test "valid submission creates survey" do
    assert_difference("SatisfactionSurvey.count", 1) do
      post submit_url,
           params: {
             rating: 5,
             comment: "Excellent attention."
           }
    end

    assert_response :success
  end

  test "valid submission stores rating and comment" do
    post submit_url,
         params: {
           rating: 4,
           comment: "The service was very helpful."
         }

    survey = @ticket.reload.satisfaction_survey

    assert_response :success
    assert_equal 4, survey.rating
    assert_equal "The service was very helpful.", survey.comment
    assert_equal Time.current, survey.submitted_at
  end

  test "duplicate submission is rejected" do
    SatisfactionSurvey.create!(
      ticket: @ticket,
      rating: 5,
      submitted_at: Time.current
    )

    assert_no_difference("SatisfactionSurvey.count") do
      post submit_url,
           params: {
             rating: 3,
             comment: "Second response."
           }
    end

    assert_response :unprocessable_entity
    assert_includes(
      inertia_page.fetch("props").fetch("errors"),
      "Ticket already has a satisfaction survey"
    )
  end

  test "successful submission shows confirmation" do
    post submit_url,
         params: {
           rating: 5,
           comment: nil
         }

    assert_response :success
    assert_equal true,
                 inertia_page.fetch("props").fetch("submitted")
    assert_empty inertia_page.fetch("props").fetch("errors")
  end

  private

  def survey_url
    satisfaction_survey_url(
      survey_token: @ticket.survey_token
    )
  end

  def submit_url
    submit_satisfaction_survey_url(
      survey_token: @ticket.survey_token
    )
  end

  def inertia_page
    page_element = Nokogiri::HTML(response.body).at_css(
      'script[data-page="app"]'
    )

    raise "Inertia page data was not found" unless page_element

    JSON.parse(page_element.text)
  end
end
