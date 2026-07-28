module Analytics
  class OperationalRecommendationEvaluator
    HIGH_WAIT_TIME_THRESHOLD_MINUTES = 20.0
    HIGH_ATTENTION_TIME_THRESHOLD_MINUTES = 30.0
    HIGH_NO_SHOW_RATE_THRESHOLD_PERCENTAGE = 10.0
    SATURATED_SERVICE_DEMAND_SHARE_THRESHOLD_PERCENTAGE = 40.0
    PEAK_DEMAND_HOUR_SHARE_THRESHOLD_PERCENTAGE = 20.0

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

        items << high_wait_time_recommendation if high_wait_time?
        if high_attention_time?
          items << high_attention_time_recommendation
        end

        items << high_no_show_rate_recommendation if high_no_show_rate?
        items << saturated_service_recommendation if saturated_service
      items << peak_demand_hour_recommendation if peak_demand_hour
      end
    end

    def peak_demand_hour_recommendation
      hour = peak_demand_hour

      {
        code: "peak_demand_hour",
        title: "Historical peak demand hour",
        description: "This hour concentrates a high share of historical demand.",
        severity: "warning",
        suggested_action: "Review staffing coverage before and during this hour.",
        evidence: {
          metric_name: "hourly_demand_share_percentage",
          observed_value: hour[:share_percentage],
          threshold_value: PEAK_DEMAND_HOUR_SHARE_THRESHOLD_PERCENTAGE,
          hour: hour[:hour],
          context: "historical_operational_profile"
        }
      }
    end

    def peak_demand_hour
      Array(metrics[:hourly_distribution])
        .select do |hour|
          hour[:share_percentage].to_f >
            PEAK_DEMAND_HOUR_SHARE_THRESHOLD_PERCENTAGE
        end
        .max_by do |hour|
          [
            hour[:share_percentage].to_f,
            -hour[:hour].to_i
          ]
        end
    end

    def saturated_service_recommendation
      service = saturated_service

      {
        code: "saturated_service",
        title: "Historically saturated service",
        description: "#{service[:service_name]} concentrates a high share of historical demand.",
        severity: "warning",
        suggested_action: "Review staffing and service-window capacity for this service.",
        evidence: {
          metric_name: "service_demand_share_percentage",
          observed_value: service[:share_percentage],
          threshold_value: SATURATED_SERVICE_DEMAND_SHARE_THRESHOLD_PERCENTAGE,
          service_name: service[:service_name],
          service_code: service[:service_code],
          context: "historical_operational_profile"
        }
      }
    end

    def saturated_service
      Array(metrics[:service_distribution])
        .select do |service|
          service[:share_percentage].to_f >
            SATURATED_SERVICE_DEMAND_SHARE_THRESHOLD_PERCENTAGE
        end
        .max_by { |service| service[:share_percentage].to_f }
    end

    def high_attention_time?
      metrics.fetch(:average_attention_time_minutes, 0).to_f >
        HIGH_ATTENTION_TIME_THRESHOLD_MINUTES
    end

    def high_attention_time_recommendation
      {
        code: "high_attention_time",
        title: "High historical attention time",
        description: "The historical average attention time exceeds the configured threshold.",
        severity: "warning",
        suggested_action: "Review service procedures and sources of attention delays.",
        evidence: {
          metric_name: "average_attention_time_minutes",
          observed_value: metrics[:average_attention_time_minutes],
          threshold_value: HIGH_ATTENTION_TIME_THRESHOLD_MINUTES,
          context: "historical_operational_profile"
        }
      }
    end

    def high_no_show_rate?
      no_show_rate_percentage >
        HIGH_NO_SHOW_RATE_THRESHOLD_PERCENTAGE
    end

    def no_show_rate_percentage
      (
        metrics.fetch(:tickets_no_show, 0).to_f /
        metrics.fetch(:tickets_created) * 100
      ).round(2)
    end

    def high_no_show_rate_recommendation
      {
        code: "high_no_show_rate",
        title: "High historical no-show rate",
        description: "The historical no-show rate exceeds the configured threshold.",
        severity: "warning",
        suggested_action: "Review reminders and ticket confirmation procedures.",
        evidence: {
          metric_name: "no_show_rate_percentage",
          observed_value: no_show_rate_percentage,
          threshold_value: HIGH_NO_SHOW_RATE_THRESHOLD_PERCENTAGE,
          context: "historical_operational_profile"
        }
      }
    end

    def high_wait_time?
      metrics.fetch(:average_wait_time_minutes, 0).to_f >
        HIGH_WAIT_TIME_THRESHOLD_MINUTES
    end

    def high_wait_time_recommendation
      {
        code: "high_wait_time",
        title: "High historical wait time",
        description: "The historical average wait time exceeds 20 minutes.",
        severity: "warning",
        suggested_action: "Review staffing and service-window capacity.",
        evidence: {
          metric_name: "average_wait_time_minutes",
          observed_value: metrics[:average_wait_time_minutes],
          threshold_value: HIGH_WAIT_TIME_THRESHOLD_MINUTES,
          context: "historical_operational_profile"
        }
      }
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
