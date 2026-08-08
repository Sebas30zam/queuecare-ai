module Analytics
  class HistoricalOperationalProfileService
    def initialize(cutoff_date:, period_days:)
      @cutoff_date = normalize_cutoff_date(cutoff_date)
      @period_days = period_days

      validate_period_days!
    end

    def call
      tickets = HistoricalTicketsQuery.new(
        start_date:,
        cutoff_date:
      ).call

      metrics = HistoricalMetricsCalculator.new(
        tickets:,
        period_days:,
        start_date:
      ).call

      {
        period: {
          start_date: start_date.iso8601,
          end_date: cutoff_date.prev_day.iso8601,
          period_days:
        },
        metrics:
      }
    end

    private

    attr_reader :cutoff_date, :period_days

    def start_date
      cutoff_date - period_days
    end

    def normalize_cutoff_date(value)
      return value if value.is_a?(Date)
      return Date.iso8601(value) if value.is_a?(String)

      raise ArgumentError, "cutoff_date must be a valid date"
    rescue Date::Error
      raise ArgumentError, "cutoff_date must be a valid date"
    end

    def validate_period_days!
      return if period_days.is_a?(Integer) && period_days.positive?

      raise ArgumentError, "period_days must be greater than zero"
    end
  end
end
