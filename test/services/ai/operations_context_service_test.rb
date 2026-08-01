require "test_helper"

class Ai::OperationsContextServiceTest < ActiveSupport::TestCase
  test "combines current metrics and operational analysis" do
    target_date = Date.new(2026, 8, 1)

    operational_metrics = {
      summary: {
        tickets_created: 25,
        tickets_attended: 20
      }
    }

    operational_analysis = {
      status: "ready",
      recommendations: [
        {
          code: "high_wait_time",
          severity: "warning"
        }
      ],
      historical_profile: {
        metrics: {
          tickets_created: 300
        }
      },
      calendar_context: {
        holiday: false
      },
      next_holiday_alert: nil
    }

    metrics_service_class =
      ServiceClassStub.new(operational_metrics)

    recommendations_service_class =
      ServiceClassStub.new(operational_analysis)

    result = Ai::OperationsContextService.new(
      date: target_date,
      operational_metrics_service_class:
        metrics_service_class,
      operational_recommendations_service_class:
        recommendations_service_class
    ).call

    assert_equal "2026-08-01", result[:date]
    assert_equal(
      operational_metrics,
      result[:operational_metrics]
    )
    assert_equal(
      operational_analysis,
      result[:operational_analysis]
    )

    assert_equal(
      [ { date: target_date } ],
      metrics_service_class.received_arguments
    )

    assert_equal(
      [ { date: target_date } ],
      recommendations_service_class.received_arguments
    )
  end

  private

  class ServiceClassStub
    attr_reader :received_arguments

    def initialize(result)
      @result = result
      @received_arguments = []
    end

    def new(date:)
      received_arguments << { date: }

      CallableStub.new(@result)
    end
  end

  class CallableStub
    def initialize(result)
      @result = result
    end

    def call
      @result
    end
  end
end
