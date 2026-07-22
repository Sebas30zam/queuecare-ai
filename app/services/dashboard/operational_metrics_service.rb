module Dashboard
  class OperationalMetricsService
    ROUNDING_PRECISION = 2
    SECONDS_PER_MINUTE = 60.0

    PENDING_STATUS = "pending".freeze
    CALLED_STATUS = "called".freeze
    IN_ATTENTION_STATUS = "in_attention".freeze
    ATTENDED_STATUS = "attended".freeze
    NO_SHOW_STATUS = "no_show".freeze
    CANCELLED_STATUS = "cancelled".freeze

    STATUS_ORDER = [
      PENDING_STATUS,
      CALLED_STATUS,
      IN_ATTENTION_STATUS,
      ATTENDED_STATUS,
      NO_SHOW_STATUS,
      CANCELLED_STATUS
    ].freeze

    def initialize(date: Date.current)
      @date = date
    end

    def call
      tickets = tickets_for_date.to_a
      services = active_services.to_a
      summary = metrics_for(tickets)
      service_rows = service_metrics(tickets, services)
      hourly_rows = hourly_activity(tickets)
      critical_rows = critical_service_metrics(service_rows, summary)

      {
        date: date.iso8601,
        summary: summary,
        services: service_rows,
        hourly_activity: hourly_rows,
        status_distribution: status_distribution(tickets),
        service_windows: service_window_metrics(tickets),
        critical_services: critical_rows,
        insights: operational_insights(
          hourly_rows,
          critical_rows
        )
      }
    end

    private

    attr_reader :date

    def day_range
      date.in_time_zone.all_day
    end

    def tickets_for_date
      Ticket
        .includes(:satisfaction_survey)
        .where(created_at: day_range)
    end

    def active_services
      QueueService
        .where(active: true)
        .order(:code)
    end

    def active_service_windows
      ServiceWindow
        .includes(:queue_service)
        .where(active: true)
        .order(:code)
    end

    def service_metrics(tickets, services)
      tickets_by_service = tickets.group_by(&:queue_service_id)

      services.map do |queue_service|
        metrics_for(
          tickets_by_service.fetch(queue_service.id, [])
        ).merge(
          id: queue_service.id,
          name: queue_service.name,
          code: queue_service.code
        )
      end
    end

    def hourly_activity(tickets)
      return [] if tickets.empty?

      counts_by_hour = tickets.group_by do |ticket|
        ticket.created_at.in_time_zone.hour
      end

      first_hour, last_hour = counts_by_hour.keys.minmax

      (first_hour..last_hour).map do |hour|
        {
          hour: hour,
          label: format("%02d:00", hour),
          tickets_created: counts_by_hour.fetch(hour, []).size
        }
      end
    end

    def status_distribution(tickets)
      STATUS_ORDER.map do |status|
        {
          status: status,
          count: count_status(tickets, status)
        }
      end
    end

    def service_window_metrics(tickets)
      tickets_by_window = tickets
                          .select { |ticket| ticket.service_window_id.present? }
                          .group_by(&:service_window_id)

      assigned_ticket_count = tickets_by_window.values.sum(&:size)

      active_service_windows.map do |service_window|
        window_tickets = tickets_by_window.fetch(service_window.id, [])
        ticket_count = window_tickets.size

        {
          id: service_window.id,
          name: service_window.name,
          code: service_window.code,
          queue_service: {
            id: service_window.queue_service.id,
            name: service_window.queue_service.name,
            code: service_window.queue_service.code
          },
          tickets_created: ticket_count,
          ticket_share_percentage: percentage(
            ticket_count,
            assigned_ticket_count
          )
        }
      end.sort_by do |window|
        [ -window[:tickets_created], window[:code] ]
      end
    end

    def critical_service_metrics(services, summary)
      average_wait = summary[:average_wait_time_minutes]

      sorted_services = services.sort_by do |service|
        wait_time = service[:average_wait_time_minutes]

        [
          wait_time.nil? ? 1 : 0,
          -(wait_time || 0),
          service[:name]
        ]
      end

      highest_wait = sorted_services
                     .filter_map { |service| service[:average_wait_time_minutes] }
                     .max

      sorted_services.map do |service|
        service.merge(
          operational_status: operational_status(
            service[:average_wait_time_minutes],
            average_wait,
            highest_wait
          )
        )
      end
    end

    def operational_insights(hourly_rows, critical_rows)
      peak_hour = hourly_rows.max_by do |item|
        [ item[:tickets_created], -item[:hour] ]
      end

      highest_wait_service = critical_rows.find do |service|
        service[:average_wait_time_minutes].present?
      end

      {
        peak_hour: peak_hour,
        highest_wait_service: serialize_wait_service(
          highest_wait_service
        )
      }
    end

    def serialize_wait_service(service)
      return nil unless service

      {
        id: service[:id],
        name: service[:name],
        code: service[:code],
        average_wait_time_minutes: service[:average_wait_time_minutes]
      }
    end

    def operational_status(wait_time, average_wait, highest_wait)
      return "no_data" if wait_time.nil?
      return "normal" if average_wait.nil?

      if highest_wait.present? &&
         wait_time == highest_wait &&
         wait_time > average_wait
        return "critical"
      end

      return "attention" if wait_time > average_wait

      "normal"
    end

    def metrics_for(tickets)
      submitted_surveys = tickets.filter_map do |ticket|
        survey = ticket.satisfaction_survey
        survey if survey&.submitted_at.present?
      end

      {
        tickets_created: tickets.size,
        tickets_attended: count_status(tickets, ATTENDED_STATUS),
        tickets_pending: count_status(tickets, PENDING_STATUS),
        tickets_no_show: count_status(tickets, NO_SHOW_STATUS),
        tickets_cancelled: count_status(tickets, CANCELLED_STATUS),
        average_wait_time_minutes: average_wait_time(tickets),
        average_attention_time_minutes: average_attention_time(tickets),
        average_satisfaction_rating: average_rating(submitted_surveys),
        survey_response_count: submitted_surveys.size
      }
    end

    def count_status(tickets, status)
      tickets.count { |ticket| ticket.status == status }
    end

    def average_wait_time(tickets)
      durations = tickets.filter_map do |ticket|
        next if ticket.called_at.blank?

        (ticket.called_at - ticket.created_at) / SECONDS_PER_MINUTE
      end

      rounded_average(durations)
    end

    def average_attention_time(tickets)
      durations = tickets.filter_map do |ticket|
        next if ticket.started_at.blank? || ticket.finished_at.blank?

        (ticket.finished_at - ticket.started_at) / SECONDS_PER_MINUTE
      end

      rounded_average(durations)
    end

    def average_rating(surveys)
      rounded_average(surveys.map(&:rating))
    end

    def rounded_average(values)
      return nil if values.empty?

      (values.sum.to_f / values.size).round(ROUNDING_PRECISION)
    end

    def percentage(value, total)
      return 0.0 if total.zero?

      ((value.to_f / total) * 100).round(ROUNDING_PRECISION)
    end
  end
end
