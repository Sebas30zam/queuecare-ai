require "test_helper"

class Analytics::CalendarContextServiceTest < ActiveSupport::TestCase
  setup do
    @service = Analytics::CalendarContextService.new
  end

  test "uses the configured country code by default" do
    assert_equal "CR", @service.country_code
  end

  test "normalizes an explicitly provided country code" do
    service = Analytics::CalendarContextService.new(
      country_code: " cr "
    )

    assert_equal "CR", service.country_code
  end

  test "returns deterministic calendar information for a regular date" do
    result = @service.call(date: "2026-04-13")

    assert_equal "2026-04-13", result[:date]
    assert_equal "CR", result[:country_code]
    assert_equal "monday", result[:day_of_week]
    assert_equal 1, result[:day_of_week_index]
    assert_not result[:weekend]
    assert_not result[:holiday]
    assert_empty result[:holidays]
  end

  test "returns all holiday metadata for the requested date" do
    result = @service.call(date: Date.new(2026, 4, 11))

    assert result[:holiday]
    assert_equal 1, result[:holidays].size

    holiday = result[:holidays].first

    assert_equal "Juan Santamaría Day", holiday[:name]
    assert holiday[:national_holiday]
    assert_equal [ "Public" ], holiday[:holiday_types]
    assert_nil holiday[:subdivision_codes]
  end

  test "returns the closest previous and next holiday dates" do
    result = @service.call(date: Date.new(2026, 4, 12))

    assert_equal "2026-04-11", result.dig(
      :previous_holiday,
      :date
    )
    assert_equal(
      [ "Juan Santamaría Day" ],
      result.dig(:previous_holiday, :names)
    )
    assert_equal 1, result.dig(
      :previous_holiday,
      :days_away
    )

    assert_equal "2026-09-15", result.dig(
      :next_holiday,
      :date
    )
    assert_equal(
      [ "Independence Day" ],
      result.dig(:next_holiday, :names)
    )
  end

  test "identifies a date directly adjacent to a holiday" do
    adjacent_result = @service.call(
      date: Date.new(2026, 4, 12)
    )
    regular_result = @service.call(
      date: Date.new(2026, 5, 1)
    )

    assert adjacent_result[:adjacent_to_holiday]
    assert_not regular_result[:adjacent_to_holiday]
  end

  test "returns nil proximity values when the country has no holidays" do
    service = Analytics::CalendarContextService.new(
      country_code: "US"
    )

    result = service.call(date: Date.new(2026, 4, 12))

    assert_not result[:holiday]
    assert_empty result[:holidays]
    assert_nil result[:previous_holiday]
    assert_nil result[:next_holiday]
    assert_not result[:adjacent_to_holiday]
  end

  test "rejects an invalid date" do
    error = assert_raises(ArgumentError) do
      @service.call(date: "not-a-date")
    end

    assert_equal "date must be a valid date", error.message
  end
end
