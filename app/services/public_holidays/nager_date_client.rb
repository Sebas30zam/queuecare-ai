require "date"
require "json"
require "net/http"
require "uri"

module PublicHolidays
  class NagerDateClient
    class Error < StandardError; end
    class ConnectionError < Error; end
    class InvalidResponseError < Error; end

    class HttpError < Error
      attr_reader :status_code

      def initialize(status_code)
        @status_code = status_code
        super("Nager.Date returned HTTP status #{status_code}")
      end
    end

    def initialize(config: Rails.application.config.x.public_holidays)
      @base_url = config.base_url.to_s.delete_suffix("/")
      @default_country_code = config.country_code
      @open_timeout = config.open_timeout
      @read_timeout = config.read_timeout
    end

    def fetch(year:, country_code: nil)
      normalized_year = normalize_year(year)
      normalized_country_code =
        normalize_country_code(country_code || @default_country_code)

      response = perform_request(
        build_uri(
          year: normalized_year,
          country_code: normalized_country_code
        )
      )

      raise HttpError, response.code unless response.is_a?(Net::HTTPSuccess)

      normalize_response(
        response.body,
        expected_country_code: normalized_country_code
      )
    rescue JSON::ParserError => error
      raise InvalidResponseError,
            "Nager.Date returned invalid JSON: #{error.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError,
           Errno::ECONNREFUSED, Errno::EHOSTUNREACH => error
      raise ConnectionError,
            "Unable to connect to Nager.Date: #{error.message}"
    end

    private

    def normalize_year(year)
      normalized_year = Integer(year, exception: false)

      return normalized_year if normalized_year&.between?(1, 9999)

      raise ArgumentError, "year must be an integer between 1 and 9999"
    end

    def normalize_country_code(country_code)
      normalized_country_code = country_code.to_s.strip.upcase

      return normalized_country_code if normalized_country_code.match?(/\A[A-Z]{2}\z/)

      raise ArgumentError, "country_code must contain exactly two letters"
    end

    def build_uri(year:, country_code:)
      URI.parse("#{@base_url}/Holidays/#{country_code}/#{year}")
    rescue URI::InvalidURIError => error
      raise ArgumentError, "invalid public holidays API URL: #{error.message}"
    end

    def perform_request(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      ) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
    end

    def normalize_response(body, expected_country_code:)
      holidays = JSON.parse(body)

      unless holidays.is_a?(Array)
        raise InvalidResponseError,
              "Nager.Date response must be an array"
      end

      holidays.each_with_index.map do |holiday, index|
        normalize_holiday(
          holiday,
          index: index,
          expected_country_code: expected_country_code
        )
      end
    end

    def normalize_holiday(holiday, index:, expected_country_code:)
      unless holiday.is_a?(Hash)
        raise InvalidResponseError,
              "holiday at index #{index} must be an object"
      end

      {
        date: parse_date(holiday["date"], index: index),
        name: required_string(holiday["name"], field: "name", index: index),
        country_code: validate_response_country(
          holiday["countryCode"],
          expected: expected_country_code,
          index: index
        ),
        national_holiday: required_boolean(
          holiday["global"],
          field: "global",
          index: index
        ),
        subdivision_codes: optional_string_array(
          holiday["counties"],
          field: "counties",
          index: index
        ),
        holiday_types: required_string_array(
          holiday["types"],
          field: "types",
          index: index
        )
      }
    end

    def parse_date(value, index:)
      Date.iso8601(value.to_s)
    rescue Date::Error
      raise InvalidResponseError,
            "date at index #{index} must use ISO 8601 format"
    end

    def required_string(value, field:, index:)
      return value if value.is_a?(String) && value.present?

      raise InvalidResponseError,
            "#{field} at index #{index} must be a non-empty string"
    end

    def required_boolean(value, field:, index:)
      return value if [ true, false ].include?(value)

      raise InvalidResponseError,
            "#{field} at index #{index} must be a boolean"
    end

    def required_string_array(value, field:, index:)
      return value if value.is_a?(Array) && value.all?(String)

      raise InvalidResponseError,
            "#{field} at index #{index} must be an array of strings"
    end

    def optional_string_array(value, field:, index:)
      return if value.nil?

      required_string_array(value, field: field, index: index)
    end

    def validate_response_country(value, expected:, index:)
      normalized_value = required_string(
        value,
        field: "countryCode",
        index: index
      ).upcase

      return normalized_value if normalized_value == expected

      raise InvalidResponseError,
            "countryCode at index #{index} does not match #{expected}"
    end
  end
end
