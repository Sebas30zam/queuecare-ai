module Ai
  class OperationsContextService
    def initialize(
      date:,
      operational_metrics_service_class:
        Dashboard::OperationalMetricsService,
      operational_recommendations_service_class:
        Analytics::OperationalRecommendationsService
    )
      @date = date
      @operational_metrics_service_class =
        operational_metrics_service_class
      @operational_recommendations_service_class =
        operational_recommendations_service_class
    end

    def call
      {
        date: date.iso8601,
        operational_metrics: operational_metrics,
        operational_analysis: operational_analysis
      }
    end

    private

    attr_reader :date,
                :operational_metrics_service_class,
                :operational_recommendations_service_class

    def operational_metrics
      operational_metrics_service_class
        .new(date:)
        .call
    end

    def operational_analysis
      operational_recommendations_service_class
        .new(date:)
        .call
    end
  end
end
