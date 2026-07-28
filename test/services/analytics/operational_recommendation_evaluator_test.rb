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
  test "recommends action when a service exceeds the demand share threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 50,
        tickets_no_show: 0,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0,
        service_distribution: [
          {
            service_name: "Admissions",
            service_code: "ADM",
            tickets_created: 30,
            share_percentage: 60.0
          },
          {
            service_name: "Finance",
            service_code: "FIN",
            tickets_created: 20,
            share_percentage: 40.0
          }
        ]
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

    assert_equal "saturated_service", recommendation[:code]
    assert_equal "Historically saturated service", recommendation[:title]
    assert_predicate recommendation[:description], :present?
    assert_equal "warning", recommendation[:severity]
    assert_predicate recommendation[:suggested_action], :present?
    assert_equal(
      {
        metric_name: "service_demand_share_percentage",
        observed_value: 60.0,
        threshold_value: 40.0,
        service_name: "Admissions",
        service_code: "ADM",
        context: "historical_operational_profile"
      },
      recommendation[:evidence]
    )
  end

  test "does not recommend action when the highest service demand share equals the threshold" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 100,
        tickets_no_show: 0,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0,
        service_distribution: [
          {
            service_name: "Admissions",
            service_code: "ADM",
            tickets_created: 40,
            share_percentage: 40.0
          },
          {
            service_name: "Finance",
            service_code: "FIN",
            tickets_created: 35,
            share_percentage: 35.0
          },
          {
            service_name: "Registration",
            service_code: "REG",
            tickets_created: 25,
            share_percentage: 25.0
          }
        ]
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

  test "recommends the service with the highest demand share" do
    evaluator = Analytics::OperationalRecommendationEvaluator.new(
      metrics: {
        tickets_created: 100,
        tickets_no_show: 0,
        average_wait_time_minutes: 20.0,
        average_attention_time_minutes: 30.0,
        service_distribution: [
          {
            service_name: "Admissions",
            service_code: "ADM",
            tickets_created: 41,
            share_percentage: 41.0
          },
          {
            service_name: "Finance",
            service_code: "FIN",
            tickets_created: 42,
            share_percentage: 42.0
          },
          {
            service_name: "Registration",
            service_code: "REG",
            tickets_created: 17,
            share_percentage: 17.0
          }
        ]
      },
      calendar_context: {
        holiday: false,
        adjacent_to_holiday: false
      }
    )

    result = evaluator.call

    assert_equal 1, result[:recommendations].size
    assert_equal(
      "FIN",
      result[:recommendations].first.dig(:evidence, :service_code)
    )
    assert_equal(
      42.0,
      result[:recommendations].first.dig(:evidence, :observed_value)
    )
  end
end
