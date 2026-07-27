module Analytics
  class HistoricalTicketsQuery
    def initialize(start_date:, cutoff_date:)
      @start_date = start_date
      @cutoff_date = cutoff_date

      validate_period!
    end

    def call
      Ticket
        .includes(:satisfaction_survey)
        .where(created_at: historical_period)
        .order(:created_at, :id)
    end

    private

    attr_reader :start_date, :cutoff_date

    def historical_period
      Range.new(
        start_date.in_time_zone.beginning_of_day,
        cutoff_date.in_time_zone.beginning_of_day,
        true
      )
    end

    def validate_period!
      return if start_date < cutoff_date

      raise ArgumentError, "start_date must be before cutoff_date"
    end
  end
end
