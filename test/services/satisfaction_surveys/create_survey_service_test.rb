require "test_helper"

class SatisfactionSurveys::CreateSurveyServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 9, 12, 30, 0)

    @ticket = tickets(:self_service_ticket)
    @ticket.update!(
      service_window: service_windows(:window_one),
      status: "attended",
      finished_at: 5.minutes.ago
    )
  end

  teardown do
    travel_back
  end

  test "creates survey for attended ticket" do
    assert_difference("SatisfactionSurvey.count", 1) do
      result = create_survey

      assert result.success?
      assert_instance_of SatisfactionSurvey, result.survey
      assert_empty result.errors
    end
  end

  test "sets submitted at" do
    result = create_survey

    assert result.success?
    assert_equal Time.current, result.survey.submitted_at
  end

  test "stores rating" do
    result = create_survey(rating: 4)

    assert result.success?
    assert_equal 4, result.survey.rating
  end

  test "stores optional comment" do
    result = create_survey(comment: "Very helpful attention.")

    assert result.success?
    assert_equal "Very helpful attention.", result.survey.comment
  end

  test "rejects pending ticket" do
    assert_rejects_status("pending")
  end

  test "rejects called ticket" do
    assert_rejects_status("called")
  end

  test "rejects in attention ticket" do
    assert_rejects_status("in_attention")
  end

  test "rejects no show ticket" do
    assert_rejects_status("no_show")
  end

  test "rejects cancelled ticket" do
    assert_rejects_status("cancelled")
  end

  test "rejects ticket without finished at" do
    @ticket.update!(finished_at: nil)

    result = create_survey

    assert_not result.success?
    assert_nil result.survey
    assert_includes result.errors, "Finished at is required"
    assert_not SatisfactionSurvey.exists?(ticket: @ticket)
  end

  test "rejects duplicate survey" do
    SatisfactionSurvey.create!(
      ticket: @ticket,
      rating: 5,
      submitted_at: Time.current
    )

    result = create_survey

    assert_not result.success?
    assert_nil result.survey
    assert_includes(
      result.errors,
      "Ticket already has a satisfaction survey"
    )
    assert_equal 1, SatisfactionSurvey.where(ticket: @ticket).count
  end

  test "rejects invalid rating" do
    result = create_survey(rating: 6)

    assert_not result.success?
    assert_instance_of SatisfactionSurvey, result.survey
    assert result.errors.any?
    assert_not SatisfactionSurvey.exists?(ticket: @ticket)
  end

  test "rejects missing ticket" do
    result = SatisfactionSurveys::CreateSurveyService.new(
      ticket: nil,
      rating: 5,
      comment: nil
    ).call

    assert_not result.success?
    assert_nil result.survey
    assert_includes result.errors, "Ticket is required"
  end

  private

  def create_survey(rating: 5, comment: "Excellent service.")
    SatisfactionSurveys::CreateSurveyService.new(
      ticket: @ticket,
      rating: rating,
      comment: comment
    ).call
  end

  def assert_rejects_status(status)
    @ticket.update!(
      status: status,
      finished_at: nil
    )

    result = create_survey

    assert_not result.success?
    assert_nil result.survey
    assert_includes(
      result.errors,
      "Ticket must be attended before submitting a survey"
    )
    assert_not SatisfactionSurvey.exists?(ticket: @ticket)
  end
end
