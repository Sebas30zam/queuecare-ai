require "test_helper"

class SatisfactionSurveyTest < ActiveSupport::TestCase
  test "valid survey" do
    survey = build_survey

    assert survey.valid?
  end

  test "requires ticket" do
    survey = build_survey(ticket: nil)

    assert_not survey.valid?
    assert survey.errors[:ticket].any?
  end

  test "requires rating" do
    survey = build_survey(rating: nil)

    assert_not survey.valid?
    assert survey.errors[:rating].any?
  end

  test "rating must be integer" do
    survey = build_survey(rating: 3.5)

    assert_not survey.valid?
    assert survey.errors[:rating].any?
  end

  test "rating must be at least 1" do
    survey = build_survey(rating: 0)

    assert_not survey.valid?
    assert survey.errors[:rating].any?
  end

  test "rating must be at most 5" do
    survey = build_survey(rating: 6)

    assert_not survey.valid?
    assert survey.errors[:rating].any?
  end

  test "comment is optional" do
    survey = build_survey(comment: nil)

    assert survey.valid?
  end

  test "only one survey per ticket" do
    ticket = tickets(:self_service_ticket)

    SatisfactionSurvey.create!(
      ticket: ticket,
      rating: 5,
      submitted_at: Time.current
    )

    duplicate_survey = build_survey(ticket: ticket)

    assert_not duplicate_survey.valid?
    assert duplicate_survey.errors[:ticket_id].any?
  end

  private

  def build_survey(attributes = {})
    SatisfactionSurvey.new(
      {
        ticket: tickets(:self_service_ticket),
        rating: 5,
        comment: "Excellent service.",
        submitted_at: Time.current
      }.merge(attributes)
    )
  end
end
