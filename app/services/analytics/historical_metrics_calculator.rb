module Analytics
  class HistoricalMetricsCalculator
    ATTENDED_STATUS = "attended"
    NO_SHOW_STATUS = "no_show"
    CANCELLED_STATUS = "cancelled"
    SECONDS_PER_MINUTE = 60.0
    ROUNDING_PRECISION = 2

    def initialize(tickets:, period_days:)
      @tickets = tickets.to_a
      @period_days = period_days

      validate_period_days!
    end

    def call
      submitted_surveys = tickets.filter_map do |ticket|
        survey = ticket.satisfaction_survey
        survey if survey&.submitted_at.present?
      end

      {
        period_days:,
        tickets_created: tickets.size,
        tickets_attended: count_status(ATTENDED_STATUS),
        tickets_no_show: count_status(NO_SHOW_STATUS),
        tickets_cancelled: count_status(CANCELLED_STATUS),
        average_daily_demand: average_daily_demand,
        average_wait_time_minutes: average_wait_time,
        average_attention_time_minutes: average_attention_time,
        no_show_rate_percentage: percentage(
          count_status(NO_SHOW_STATUS),
          tickets.size
        ),
        cancellation_rate_percentage: percentage(
          count_status(CANCELLED_STATUS),
          tickets.size
        ),
        average_satisfaction_rating: average(
          submitted_surveys.map(&:rating)
        ),
        survey_response_count: submitted_surveys.size,
        service_distribution: service_distribution,
        hourly_distribution: hourly_distribution,
        service_window_distribution: service_window_distribution
      }
    end

    private

    attr_reader :tickets, :period_days

    def validate_period_days!
      return if period_days.is_a?(Integer) && period_days.positive?

      raise ArgumentError, "period_days must be greater than zero"
    end

    def count_status(status)
      tickets.count { |ticket| ticket.status == status }
    end

    def service_distribution
      service_counts = tickets.filter_map do |ticket|
        service = ticket.queue_service
        [ service.name, service.code ] if service
      end.tally

      total = service_counts.values.sum

      service_counts.map do |(service_name, service_code), count|
        {
          service_name:,
          service_code:,
          tickets_created: count,
          share_percentage: percentage(count, total)
        }
      end.sort_by do |service|
        [
          -service[:tickets_created],
          service[:service_code]
        ]
      end
    end

def service_window_distribution
  window_counts = tickets.filter_map do |ticket|
    window = ticket.service_window
    service = window&.queue_service

    if window
      [
        window.name,
        window.code,
        service&.name,
        service&.code
      ]
    end
  end.tally

  total = window_counts.values.sum

  window_counts.map do |window_data, count|
    window_name,
      window_code,
      service_name,
      service_code = window_data

    {
      service_window_name: window_name,
      service_window_code: window_code,
      queue_service_name: service_name,
      queue_service_code: service_code,
      tickets_assigned: count,
      share_percentage: percentage(count, total)
    }
  end.sort_by do |window|
    [
      -window[:tickets_assigned],
      window[:service_window_code]
    ]
  end
end

    def hourly_distribution
      hour_counts = tickets.filter_map do |ticket|
        ticket.created_at&.in_time_zone&.hour
      end.tally

      total = hour_counts.values.sum

      hour_counts.sort_by(&:first).map do |hour, count|
        {
          hour:,
          tickets_created: count,
          share_percentage: percentage(count, total)
        }
      end
    end

    def average_daily_demand
      (tickets.size.to_f / period_days).round(ROUNDING_PRECISION)
    end

    def average_wait_time
      durations = tickets.filter_map do |ticket|
        next if ticket.called_at.blank? || ticket.created_at.blank?

        (ticket.called_at - ticket.created_at) / SECONDS_PER_MINUTE
      end

      average(durations)
    end

    def average_attention_time
      durations = tickets.filter_map do |ticket|
        next if ticket.started_at.blank? || ticket.finished_at.blank?

        (ticket.finished_at - ticket.started_at) / SECONDS_PER_MINUTE
      end

      average(durations)
    end

    def average(values)
      return if values.empty?

      (values.sum.to_f / values.size).round(ROUNDING_PRECISION)
    end

    def percentage(value, total)
      return 0.0 if total.zero?

      ((value.to_f / total) * 100).round(ROUNDING_PRECISION)
    end
  end
end
