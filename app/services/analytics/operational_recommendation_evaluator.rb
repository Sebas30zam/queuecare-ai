module Analytics
  class OperationalRecommendationEvaluator
    def initialize(metrics:, calendar_context:)
      @metrics = metrics
      @calendar_context = calendar_context
    end

    def call
      return insufficient_data_result if metrics[:tickets_created].zero?

      {
        status: "ready",
        recommendations: recommendations
      }
    end

    private

    attr_reader :metrics, :calendar_context

    def recommendations
      [].tap do |items|
        items << holiday_recommendation if calendar_context[:holiday]

        if calendar_context[:adjacent_to_holiday]
          items << adjacent_holiday_recommendation
        end
      end
    end

    def holiday_recommendation
      {
        code: "holiday_operational_review",
        priority: "attention"
      }
    end

    def adjacent_holiday_recommendation
      {
        code: "adjacent_holiday_operational_review",
        priority: "attention"
      }
    end

    def insufficient_data_result
      {
        status: "insufficient_data",
        recommendations: [
          {
            code: "insufficient_historical_data",
            priority: "information"
          }
        ]
      }
    end
  end
end
