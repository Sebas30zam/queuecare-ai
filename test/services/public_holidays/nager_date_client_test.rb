require "test_helper"

module PublicHolidays
  class NagerDateClientTest < ActiveSupport::TestCase
    setup do
      config = ActiveSupport::OrderedOptions.new
      config.base_url = "https://date.nager.at/api/v4/"
      config.country_code = "CR"
      config.open_timeout = 5
      config.read_timeout = 10

      @client = NagerDateClient.new(config: config)
      @request_url = "https://date.nager.at/api/v4/Holidays/CR/2026"
    end

    test "fetches and normalizes public holidays" do
      stub_request(:get, @request_url).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: [
          {
            "date" => "2026-01-01",
            "name" => "New Year's Day",
            "countryCode" => "CR",
            "global" => true,
            "counties" => nil,
            "types" => [ "Public" ]
          }
        ].to_json
      )

      holidays = @client.fetch(year: 2026)

      assert_equal 1, holidays.size
      assert_equal Date.new(2026, 1, 1), holidays.first[:date]
      assert_equal "New Year's Day", holidays.first[:name]
      assert_equal "CR", holidays.first[:country_code]
      assert holidays.first[:national_holiday]
      assert_nil holidays.first[:subdivision_codes]
      assert_equal [ "Public" ], holidays.first[:holiday_types]
      assert_requested :get, @request_url, times: 1
    end

    test "normalizes an overridden country code" do
      request_url = "https://date.nager.at/api/v4/Holidays/US/2026"

      stub_request(:get, request_url).to_return(
        status: 200,
        body: [
          valid_holiday.merge(
            "countryCode" => "US",
            "counties" => [ "US-CA" ]
          )
        ].to_json
      )

      holidays = @client.fetch(year: "2026", country_code: " us ")

      assert_equal "US", holidays.first[:country_code]
      assert_equal [ "US-CA" ], holidays.first[:subdivision_codes]
      assert_requested :get, request_url, times: 1
    end

    test "rejects an invalid year" do
      error = assert_raises(ArgumentError) do
        @client.fetch(year: "invalid")
      end

      assert_equal "year must be an integer between 1 and 9999", error.message
    end

    test "rejects an invalid country code" do
      error = assert_raises(ArgumentError) do
        @client.fetch(year: 2026, country_code: "CRI")
      end

      assert_equal(
        "country_code must contain exactly two letters",
        error.message
      )
    end

    test "raises an HTTP error for unsuccessful responses" do
      stub_request(:get, @request_url).to_return(status: 503)

      error = assert_raises(NagerDateClient::HttpError) do
        @client.fetch(year: 2026)
      end

      assert_equal "503", error.status_code
      assert_equal "Nager.Date returned HTTP status 503", error.message
    end

    test "raises an invalid response error for malformed JSON" do
      stub_request(:get, @request_url).to_return(
        status: 200,
        body: "{invalid"
      )

      error = assert_raises(NagerDateClient::InvalidResponseError) do
        @client.fetch(year: 2026)
      end

      assert_match "Nager.Date returned invalid JSON", error.message
    end

    test "requires the response to be an array" do
      stub_request(:get, @request_url).to_return(
        status: 200,
        body: valid_holiday.to_json
      )

      error = assert_raises(NagerDateClient::InvalidResponseError) do
        @client.fetch(year: 2026)
      end

      assert_equal "Nager.Date response must be an array", error.message
    end

    test "rejects a response with a different country code" do
      stub_request(:get, @request_url).to_return(
        status: 200,
        body: [ valid_holiday.merge("countryCode" => "US") ].to_json
      )

      error = assert_raises(NagerDateClient::InvalidResponseError) do
        @client.fetch(year: 2026)
      end

      assert_equal(
        "countryCode at index 0 does not match CR",
        error.message
      )
    end

    test "rejects invalid holiday field types" do
      stub_request(:get, @request_url).to_return(
        status: 200,
        body: [ valid_holiday.merge("global" => "true") ].to_json
      )

      error = assert_raises(NagerDateClient::InvalidResponseError) do
        @client.fetch(year: 2026)
      end

      assert_equal "global at index 0 must be a boolean", error.message
    end

    test "wraps connection timeouts" do
      stub_request(:get, @request_url).to_timeout

      error = assert_raises(NagerDateClient::ConnectionError) do
        @client.fetch(year: 2026)
      end

      assert_match "Unable to connect to Nager.Date", error.message
    end

    private

    def valid_holiday
      {
        "date" => "2026-01-01",
        "name" => "New Year's Day",
        "countryCode" => "CR",
        "global" => true,
        "counties" => nil,
        "types" => [ "Public" ]
      }
    end
  end
end
