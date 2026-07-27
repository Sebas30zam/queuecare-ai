module Analytics
  class CalendarContextService
    WEEKEND_DAYS = [ 0, 6 ].freeze

    attr_reader :country_code

    def initialize(
      country_code: Rails.application.config.x.public_holidays.country_code
    )
      @holiday_query = PublicHolidays::QueryService.new(country_code:)
      @country_code = @holiday_query.country_code
    end

    def call(date:)
      requested_date = parse_date(date)
      holidays = holiday_query.on(date: requested_date).to_a
      previous_holiday = previous_holiday_before(requested_date)
      next_holiday = holiday_query.next_after(date: requested_date)

      {
        date: requested_date.iso8601,
        country_code:,
        day_of_week: requested_date.strftime("%A").downcase,
        day_of_week_index: requested_date.wday,
        weekend: WEEKEND_DAYS.include?(requested_date.wday),
        holiday: holidays.any?,
        holidays: holidays.map { |holiday| holiday_metadata(holiday) },
        previous_holiday: proximity_metadata(
          previous_holiday,
          requested_date
        ),
        next_holiday: proximity_metadata(
          next_holiday,
          requested_date
        ),
        adjacent_to_holiday: adjacent_to_holiday?(
          requested_date,
          previous_holiday,
          next_holiday
        )
      }
    end

    private

    attr_reader :holiday_query

    def previous_holiday_before(date)
      PublicHoliday
        .for_country(country_code)
        .where("date < ?", date)
        .order(date: :desc, name: :asc)
        .first
    end

    def holiday_metadata(holiday)
      {
        name: holiday.name,
        national_holiday: holiday.national_holiday,
        holiday_types: holiday.holiday_types,
        subdivision_codes: holiday.subdivision_codes
      }
    end

    def proximity_metadata(holiday, requested_date)
      return if holiday.nil?

      {
        date: holiday.date.iso8601,
        names: holiday_names_on(holiday.date),
        days_away: (holiday.date - requested_date).abs.to_i
      }
    end

    def holiday_names_on(date)
      holiday_query.on(date:).pluck(:name)
    end

    def adjacent_to_holiday?(
      requested_date,
      previous_holiday,
      next_holiday
    )
      [ previous_holiday, next_holiday ].compact.any? do |holiday|
        (holiday.date - requested_date).abs.to_i == 1
      end
    end

    def parse_date(value)
      case value
      when Date
        value
      when String
        Date.iso8601(value.strip)
      else
        raise ArgumentError
      end
    rescue ArgumentError
      raise ArgumentError, "date must be a valid date"
    end
  end
end
