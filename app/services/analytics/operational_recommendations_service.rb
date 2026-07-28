module Analytics
  class OperationalRecommendationsService
    def initialize(
      date:,
      period_days: 30,
      historical_profile_service: HistoricalOperationalProfileService.new(
        cutoff_date: date,
        period_days:
      ),
      calendar_context_service: CalendarContextService.new,
      next_holiday_alert_service_class: NextHolidayAlertService
    )
      @date = date
      @historical_profile_service = historical_profile_service
      @calendar_context_service = calendar_context_service
      @next_holiday_alert_service_class =
        next_holiday_alert_service_class
    end

    def call
      historical_profile = historical_profile_service.call
      calendar_context = calendar_context_service.call(date:)

      next_holiday_alert = next_holiday_alert_service_class.new(
        date:,
        calendar_context:
      ).call

      evaluation = OperationalRecommendationEvaluator.new(
        metrics: historical_profile.fetch(:metrics),
        calendar_context:
      ).call

      {
        historical_profile:,
        calendar_context:,
        next_holiday_alert:,
        status: evaluation[:status],
        recommendations: evaluation[:recommendations]
      }
    end

    private

    attr_reader(
      :date,
      :historical_profile_service,
      :calendar_context_service,
      :next_holiday_alert_service_class
    )
  end
end
