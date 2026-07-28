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
  test "recommends action when average wait time exceeds the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30,
        average_wait_time_minutes: 25.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal "high_wait_time", recommendation[:code]
    assert_equal "High historical wait time", recommendation[:title]
    assert_predicate recommendation[:description], :present?
    assert_equal "warning", recommendation[:severity]
    assert_predicate recommendation[:suggested_action], :present?
    assert_equal(
      {
        metric_name: "average_wait_time_minutes",
        observed_value: 25.0,
        threshold_value: 20.0,
        context: "historical_operational_profile"
      },
      recommendation[:evidence]
    )
  end

  test "does not recommend action when average wait time equals the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30,
        average_wait_time_minutes: 20.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_empty result[:recommendations]
  end

  test "recommends action when average attention time exceeds the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 35.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal "high_attention_time", recommendation[:code]
    assert_equal(
      "High historical attention time",
      recommendation[:title]
    )
    assert_predicate recommendation[:description], :present?
    assert_equal "warning", recommendation[:severity]
    assert_predicate recommendation[:suggested_action], :present?
    assert_equal(
      {
        metric_name: "average_attention_time_minutes",
        observed_value: 35.0,
        threshold_value: 30.0,
        context: "historical_operational_profile"
      },
      recommendation[:evidence]
    )
  end
  test "does not recommend action when average attention time equals the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 30,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_empty result[:recommendations]
  end

  test "recommends action when no-show rate exceeds the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 40,
        tickets_no_show: 6,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_equal 1, result[:recommendations].size

    recommendation = result[:recommendations].first

    assert_equal "high_no_show_rate", recommendation[:code]
    assert_equal(
      "High historical no-show rate",
      recommendation[:title]
    )
    assert_predicate recommendation[:description], :present?
    assert_equal "warning", recommendation[:severity]
    assert_predicate recommendation[:suggested_action], :present?
    assert_equal(
      {
        metric_name: "no_show_rate_percentage",
        observed_value: 15.0,
        threshold_value: 10.0,
        context: "historical_operational_profile"
      },
      recommendation[:evidence]
    )
  end

  test "does not recommend action when no-show rate equals the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 40,
        tickets_no_show: 4,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal "ready", result[:status]
    assert_empty result[:recommendations]
  end
end
