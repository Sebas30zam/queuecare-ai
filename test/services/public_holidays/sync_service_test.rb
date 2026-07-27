require "test_helper"

module PublicHolidays
  class SyncServiceTest < ActiveSupport::TestCase
    class FakeClient
      attr_reader :requests

      def initialize(holidays: [], error: nil)
        @holidays = holidays
        @error = error
        @requests = []
      end

      def fetch(year:, country_code:)
        requests << {
          year: year,
          country_code: country_code
        }

        raise error if error

        holidays
      end

      private

      attr_reader :holidays, :error
    end

    test "creates new holidays" do
      client = FakeClient.new(
        holidays: existing_holidays_attributes + [
          holiday_attributes(
            date: Date.new(2026, 12, 25),
            name: "Christmas Day"
          )
        ]
      )

      assert_difference("PublicHoliday.count", 1) do
        result = synchronize(client: client)

        assert result.success?
        assert_equal 1, result.created_count
        assert_equal 0, result.updated_count
        assert_equal 2, result.unchanged_count
        assert_equal 0, result.deleted_count
        assert_empty result.errors
      end

      holiday = PublicHoliday.find_by!(
        country_code: "CR",
        date: Date.new(2026, 12, 25),
        name: "Christmas Day"
      )

      assert holiday.national_holiday
      assert_equal [ "Public" ], holiday.holiday_types
    end

    test "updates changed holidays" do
      changed_holiday = holiday_attributes(
        date: Date.new(2026, 4, 11),
        name: "Juan Santamaría Day",
        national_holiday: false,
        subdivision_codes: [ "CR-A" ],
        holiday_types: [ "Observance" ]
      )

      client = FakeClient.new(
        holidays: [
          changed_holiday,
          attributes_for(public_holidays(:independence_day))
        ]
      )

      result = synchronize(client: client)

      assert result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.updated_count
      assert_equal 1, result.unchanged_count
      assert_equal 0, result.deleted_count

      holiday = public_holidays(:juan_santamaria_day).reload

      assert_not holiday.national_holiday
      assert_equal [ "CR-A" ], holiday.subdivision_codes
      assert_equal [ "Observance" ], holiday.holiday_types
    end

    test "counts unchanged holidays" do
      client = FakeClient.new(
        holidays: existing_holidays_attributes
      )

      result = synchronize(client: client)

      assert result.success?
      assert_equal 0, result.created_count
      assert_equal 0, result.updated_count
      assert_equal 2, result.unchanged_count
      assert_equal 0, result.deleted_count
    end

    test "deletes stale holidays from the synchronized country and year" do
      stale_holiday_id = public_holidays(:independence_day).id
      client = FakeClient.new(
        holidays: [
          attributes_for(public_holidays(:juan_santamaria_day))
        ]
      )

      assert_difference("PublicHoliday.count", -1) do
        result = synchronize(client: client)

        assert result.success?
        assert_equal 0, result.created_count
        assert_equal 0, result.updated_count
        assert_equal 1, result.unchanged_count
        assert_equal 1, result.deleted_count
      end

      assert_not PublicHoliday.exists?(stale_holiday_id)
    end

    test "does not delete holidays from another year or country" do
      next_year_holiday = PublicHoliday.create!(
        date: Date.new(2027, 1, 1),
        name: "New Year's Day",
        country_code: "CR",
        national_holiday: true,
        holiday_types: [ "Public" ]
      )

      other_country_holiday = PublicHoliday.create!(
        date: Date.new(2026, 7, 4),
        name: "Independence Day",
        country_code: "US",
        national_holiday: true,
        holiday_types: [ "Public" ]
      )

      client = FakeClient.new(holidays: [])

      result = synchronize(client: client)

      assert result.success?
      assert_equal 2, result.deleted_count
      assert PublicHoliday.exists?(next_year_holiday.id)
      assert PublicHoliday.exists?(other_country_holiday.id)
    end

    test "normalizes the year and country code sent to the client" do
      client = FakeClient.new(
        holidays: existing_holidays_attributes
      )

      result = synchronize(
        client: client,
        year: "2026",
        country_code: " cr "
      )

      assert result.success?
      assert_equal(
        [
          {
            year: 2026,
            country_code: "CR"
          }
        ],
        client.requests
      )
    end

    test "uses the configured country code by default" do
      client = FakeClient.new(
        holidays: existing_holidays_attributes
      )

      service = SyncService.new(
        client: client,
        default_country_code: "CR"
      )

      result = service.call(year: 2026)

      assert result.success?
      assert_equal "CR", client.requests.first[:country_code]
    end

    test "rejects an invalid year without calling the client" do
      client = FakeClient.new

      result = synchronize(client: client, year: "invalid")

      assert_not result.success?
      assert_equal(
        [ "year must be an integer between 1 and 9999" ],
        result.errors
      )
      assert_empty client.requests
      assert_equal 0, result.created_count
      assert_equal 0, result.updated_count
      assert_equal 0, result.unchanged_count
      assert_equal 0, result.deleted_count
    end

    test "rejects an invalid country code without calling the client" do
      client = FakeClient.new

      result = synchronize(
        client: client,
        country_code: "CRI"
      )

      assert_not result.success?
      assert_equal(
        [ "country_code must contain exactly two letters" ],
        result.errors
      )
      assert_empty client.requests
    end

    test "returns a failure when the client cannot fetch holidays" do
      client = FakeClient.new(
        error: NagerDateClient::ConnectionError.new(
          "Unable to connect to Nager.Date"
        )
      )

      result = synchronize(client: client)

      assert_not result.success?
      assert_equal(
        [ "Unable to connect to Nager.Date" ],
        result.errors
      )
      assert_equal 0, result.created_count
      assert_equal 0, result.updated_count
      assert_equal 0, result.unchanged_count
      assert_equal 0, result.deleted_count
    end

    test "rolls back database changes when a holiday is invalid" do
      client = FakeClient.new(
        holidays: [
          holiday_attributes(
            date: Date.new(2026, 12, 25),
            name: "Christmas Day"
          ),
          holiday_attributes(
            date: Date.new(2026, 8, 2),
            name: "",
            holiday_types: [ "Public" ]
          )
        ]
      )

      assert_no_difference("PublicHoliday.count") do
        result = synchronize(client: client)

        assert_not result.success?
        assert_match(
          "Unable to synchronize public holidays",
          result.errors.first
        )
      end

      assert_not PublicHoliday.exists?(
        country_code: "CR",
        date: Date.new(2026, 12, 25),
        name: "Christmas Day"
      )

      assert PublicHoliday.exists?(
        public_holidays(:juan_santamaria_day).id
      )

      assert PublicHoliday.exists?(
        public_holidays(:independence_day).id
      )
    end

    private

    def synchronize(
      client:,
      year: 2026,
      country_code: "CR"
    )
      SyncService.new(
        client: client,
        default_country_code: "CR"
      ).call(
        year: year,
        country_code: country_code
      )
    end

    def existing_holidays_attributes
      [
        attributes_for(public_holidays(:juan_santamaria_day)),
        attributes_for(public_holidays(:independence_day))
      ]
    end

    def attributes_for(public_holiday)
      {
        date: public_holiday.date,
        name: public_holiday.name,
        country_code: public_holiday.country_code,
        national_holiday: public_holiday.national_holiday,
        subdivision_codes: public_holiday.subdivision_codes,
        holiday_types: public_holiday.holiday_types
      }
    end

    def holiday_attributes(
      date:,
      name:,
      country_code: "CR",
      national_holiday: true,
      subdivision_codes: nil,
      holiday_types: [ "Public" ]
    )
      {
        date: date,
        name: name,
        country_code: country_code,
        national_holiday: national_holiday,
        subdivision_codes: subdivision_codes,
        holiday_types: holiday_types
      }
    end
  end
end
