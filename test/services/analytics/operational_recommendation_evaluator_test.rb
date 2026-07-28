require "test_helper"

class Analytics::OperationalRecommendationEvaluatorTest <
    ActiveSupport::TestCase
  test "reports insufficient data when no historical tickets exist" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "insufficient_data", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal(
      "insufficient_historical_data",
      recommendation[:code]
    )
    assert_equal "information", recommendation[:priority]
  end

  test "recommends an operational review for a holiday" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30
      },
      calendar_context: {
        holiday: true,
        holidays: [
          {
            name: "Independence Day",
            national_holiday: true
          }
        ],
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal(
      "holiday_operational_review",
      recommendation[:code]
    )
    assert_equal "attention", recommendation[:priority]
  end

  test "recommends an operational review next to a holiday" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: true
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal(
      "adjacent_holiday_operational_review",
      recommendation[:code]
    )
    assert_equal "attention", recommendation[:priority]
  end
end
