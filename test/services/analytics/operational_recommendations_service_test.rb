require "test_helper"

class Analytics::OperationalRecommendationsServiceTest <
    ActiveSupport::TestCase
  test "combines historical metrics and calendar context" do
    target_date = Date.new(2026, 4, 12)

    historical_profile = {
      period: {
        start_date: "2026-03-13",
        end_date: "2026-04-11",
        period_days: 30
      },
      metrics: {
        tickets_created: 30
      }
    }

    calendar_context = {
      date: "2026-04-12",
      country_code: "CR",
      holiday: false,
      adjacent_to_holiday: true
    }

    next_holiday_alert = {
      date: "2026-08-02",
      names: [ "Feast of Our Lady of the Angels" ],
      days_away: 112,
      recommended_staffing_date: "2026-08-03",
      historical_data_available: false,
      demand_change_percentage: nil,
      historical_sample: {
        post_holiday_days: 0,
        baseline_days: 5
      }
    }

    historical_service = CallableStub.new(historical_profile)
    calendar_service = CalendarCallableStub.new(calendar_context)

    next_holiday_service_class =
      NextHolidayAlertServiceClassStub.new(next_holiday_alert)

    result = Analytics::OperationalRecommendationsService.new(
      date: target_date,
      period_days: 30,
      historical_profile_service: historical_service,
      calendar_context_service: calendar_service,
      next_holiday_alert_service_class:
        next_holiday_service_class
    ).call

    assert_equal historical_profile, result[:historical_profile]
    assert_equal calendar_context, result[:calendar_context]
    assert_equal next_holiday_alert, result[:next_holiday_alert]
    assert_equal "ready", result[:status]

    assert_equal(
      [
        {
          date: target_date,
          calendar_context:
        }
      ],
      next_holiday_service_class.received_arguments
    )

    assert_equal(
      [ "adjacent_holiday_operational_review" ],
      result[:recommendations].pluck(:code)
    )

    assert_equal [ target_date ], calendar_service.received_dates
  end

  test "initializes its default historical profile service" do
    target_date = Date.new(2026, 4, 12)

    assert_nothing_raised do
      Analytics::OperationalRecommendationsService.new(
        date: target_date
      )
    end
  end

  private

  class CallableStub
    def initialize(result)
      @result = result
    end

    def call
      @result
    end
  end

  class NextHolidayAlertServiceClassStub
    attr_reader :received_arguments

    def initialize(result)
      @result = result
      @received_arguments = []
    end

    def new(date:, calendar_context:)
      received_arguments << {
        date:,
        calendar_context:
      }

      CallableStub.new(@result)
    end
  end

  class CalendarCallableStub
    attr_reader :received_dates

    def initialize(result)
      @result = result
      @received_dates = []
    end

    def call(date:)
      received_dates << date
      @result
    end
  end
end
