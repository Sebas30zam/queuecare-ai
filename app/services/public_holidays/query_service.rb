module PublicHolidays
  class QueryService
    COUNTRY_CODE_FORMAT = /\A[A-Z]{2}\z/

    attr_reader :country_code

    def initialize(
      country_code: Rails.application.config.x.public_holidays.country_code
    )
      @country_code = normalize_country_code(country_code)
    end

    def holiday?(date:)
      on(date:).exists?
    end

    def on(date:)
      holidays
        .where(date: parse_date(date, attribute: "date"))
        .order(:name)
    end

    def next_after(date:)
      holidays
        .where("date > ?", parse_date(date, attribute: "date"))
        .chronological
        .first
    end

    def between(start_date:, end_date:)
      parsed_start_date = parse_date(start_date, attribute: "start_date")
      parsed_end_date = parse_date(end_date, attribute: "end_date")

      if parsed_start_date > parsed_end_date
        raise ArgumentError, "start_date must be on or before end_date"
      end

      holidays
        .where(date: parsed_start_date..parsed_end_date)
        .chronological
    end

    private

    def holidays
      PublicHoliday.for_country(country_code)
    end

    def normalize_country_code(value)
      normalized_country_code = value.to_s.strip.upcase

      unless COUNTRY_CODE_FORMAT.match?(normalized_country_code)
        raise ArgumentError, "country_code must contain exactly two letters"
      end

      normalized_country_code
    end

    def parse_date(value, attribute:)
      case value
      when Date
        value
      when String
        Date.iso8601(value.strip)
      else
        raise ArgumentError
      end
    rescue ArgumentError
      raise ArgumentError, "#{attribute} must be a valid date"
    end
  end
end
