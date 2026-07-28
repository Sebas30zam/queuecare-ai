module Analytics
  class NextHolidayAlertService
    LOOKBACK_DAYS = 365
    MINIMUM_POST_HOLIDAY_DAYS = 2
    MINIMUM_BASELINE_DAYS = 5

    def initialize(
      date:,
      calendar_context:,
      holiday_query: PublicHolidays::QueryService.new,
      tickets_scope: Ticket.all
    )
      @date = date.to_date
      @calendar_context = calendar_context
      @holiday_query = holiday_query
      @tickets_scope = tickets_scope
    end

    def call
      next_holiday = calendar_context[:next_holiday]
      return if next_holiday.blank?

      holiday_date = Date.iso8601(next_holiday.fetch(:date))
      demand_analysis = calculate_historical_demand

      {
        date: holiday_date.iso8601,
        names: Array(next_holiday[:names]),
        days_away: next_holiday.fetch(:days_away),
        recommended_staffing_date:
          next_business_day_after(holiday_date).iso8601,
        historical_data_available:
          demand_analysis[:historical_data_available],
        demand_change_percentage:
          demand_analysis[:demand_change_percentage],
        historical_sample: demand_analysis[:historical_sample]
      }
    end

    private

    attr_reader(
      :date,
      :calendar_context,
      :holiday_query,
      :tickets_scope
    )

    def calculate_historical_demand
      ticket_counts = historical_ticket_counts
      post_holiday_dates = historical_post_holiday_dates

      post_holiday_counts = counts_for(
        dates: post_holiday_dates,
        ticket_counts:
      )

      baseline_dates = ticket_counts.keys.select do |historical_date|
        business_day?(historical_date) &&
          !historical_holiday_dates.include?(historical_date) &&
          !post_holiday_dates.include?(historical_date)
      end

      baseline_counts = counts_for(
        dates: baseline_dates,
        ticket_counts:
      )

      sample = {
        post_holiday_days: post_holiday_counts.length,
        baseline_days: baseline_counts.length
      }

      unless sufficient_data?(
        post_holiday_counts:,
        baseline_counts:
      )
        return {
          historical_data_available: false,
          demand_change_percentage: nil,
          historical_sample: sample
        }
      end

      baseline_average = average(baseline_counts)

      {
        historical_data_available: true,
        demand_change_percentage: percentage_change(
          observed_average: average(post_holiday_counts),
          baseline_average:
        ),
        historical_sample: sample
      }
    end

    def analysis_period
      (date - LOOKBACK_DAYS.days)..(date - 1.day)
    end

    def historical_ticket_counts
      tickets_scope
        .where(sequence_date: analysis_period)
        .group(:sequence_date)
        .count
        .transform_keys(&:to_date)
    end

    def historical_holiday_dates
      @historical_holiday_dates ||= holiday_query
        .between(
          start_date: analysis_period.begin,
          end_date: analysis_period.end
        )
        .map { |holiday| holiday.date.to_date }
        .uniq
    end

    def historical_post_holiday_dates
      historical_holiday_dates
        .map { |holiday_date| next_business_day_after(holiday_date) }
        .select { |historical_date| analysis_period.cover?(historical_date) }
        .uniq
    end

    def next_business_day_after(start_date)
      candidate = start_date + 1.day

      until business_day?(candidate) &&
            !holiday_query.holiday?(date: candidate)
        candidate += 1.day
      end

      candidate
    end

    def business_day?(candidate)
      !candidate.saturday? && !candidate.sunday?
    end

    def counts_for(dates:, ticket_counts:)
      dates.filter_map { |historical_date| ticket_counts[historical_date] }
    end

    def sufficient_data?(post_holiday_counts:, baseline_counts:)
      post_holiday_counts.length >= MINIMUM_POST_HOLIDAY_DAYS &&
        baseline_counts.length >= MINIMUM_BASELINE_DAYS &&
        average(baseline_counts).positive?
    end

    def average(values)
      values.sum.to_f / values.length
    end

    def percentage_change(observed_average:, baseline_average:)
      (
        (observed_average - baseline_average) /
        baseline_average *
        100
      ).round
    end
  end
end
