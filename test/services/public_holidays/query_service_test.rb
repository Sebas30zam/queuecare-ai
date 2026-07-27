require "test_helper"

class PublicHolidays::QueryServiceTest < ActiveSupport::TestCase
  setup do
    @service = PublicHolidays::QueryService.new
  end

  test "uses the configured country code by default" do
    assert_equal "CR", @service.country_code
  end

  test "normalizes an explicitly provided country code" do
    service = PublicHolidays::QueryService.new(country_code: " cr ")

    assert_equal "CR", service.country_code
  end

  test "rejects an invalid country code" do
    error = assert_raises(ArgumentError) do
      PublicHolidays::QueryService.new(country_code: "CRI")
    end

    assert_equal "country_code must contain exactly two letters", error.message
  end

  test "determines whether a date is a holiday" do
    assert @service.holiday?(date: Date.new(2026, 4, 11))
    assert_not @service.holiday?(date: Date.new(2026, 4, 12))
  end

  test "returns all holidays on a date ordered by name" do
    additional_holiday = PublicHoliday.create!(
      date: Date.new(2026, 4, 11),
      name: "Additional Holiday",
      country_code: "CR",
      national_holiday: true,
      holiday_types: [ "Public" ]
    )

    results = @service.on(date: "2026-04-11")

    assert_equal(
      [ additional_holiday, public_holidays(:juan_santamaria_day) ],
      results.to_a
    )
  end

  test "does not return holidays from another country" do
    PublicHoliday.create!(
      date: Date.new(2026, 4, 11),
      name: "Foreign Holiday",
      country_code: "US",
      national_holiday: true,
      holiday_types: [ "Public" ]
    )

    results = @service.on(date: Date.new(2026, 4, 11))

    assert_equal [ public_holidays(:juan_santamaria_day) ], results.to_a
  end

  test "returns the next holiday strictly after a date" do
    result = @service.next_after(date: Date.new(2026, 4, 11))

    assert_equal public_holidays(:independence_day), result
  end

  test "returns nil when there is no later holiday" do
    result = @service.next_after(date: Date.new(2026, 9, 15))

    assert_nil result
  end

  test "returns holidays inside an inclusive date range" do
    results = @service.between(
      start_date: "2026-04-11",
      end_date: "2026-09-15"
    )

    assert_equal(
      [
        public_holidays(:juan_santamaria_day),
        public_holidays(:independence_day)
      ],
      results.to_a
    )
  end

  test "returns no holidays when a date range has no matches" do
    results = @service.between(
      start_date: Date.new(2026, 5, 1),
      end_date: Date.new(2026, 5, 31)
    )

    assert_empty results
  end

  test "rejects a reversed date range" do
    error = assert_raises(ArgumentError) do
      @service.between(
        start_date: "2026-09-15",
        end_date: "2026-04-11"
      )
    end

    assert_equal "start_date must be on or before end_date", error.message
  end

  test "rejects invalid date values" do
    error = assert_raises(ArgumentError) do
      @service.holiday?(date: "not-a-date")
    end

    assert_equal "date must be a valid date", error.message
  end
end
