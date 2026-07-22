require "test_helper"

class PublicHolidayTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    assert public_holidays(:juan_santamaria_day).valid?
  end

  test "requires essential attributes" do
    public_holiday = PublicHoliday.new

    assert_not public_holiday.valid?
    assert public_holiday.errors.of_kind?(:date, :blank)
    assert public_holiday.errors.of_kind?(:name, :blank)
    assert public_holiday.errors.of_kind?(:country_code, :blank)
  end

  test "normalizes country code before validation" do
    public_holiday = PublicHoliday.new(country_code: " cr ")

    public_holiday.valid?

    assert_equal "CR", public_holiday.country_code
  end

  test "requires a valid two-character country code" do
    public_holiday = public_holidays(:juan_santamaria_day)
    public_holiday.country_code = "CRI"

    assert_not public_holiday.valid?
    assert public_holiday.errors.of_kind?(:country_code, :invalid)
  end

  test "prevents duplicate names for the same country and date" do
    duplicate = public_holidays(:juan_santamaria_day).dup

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end

  test "requires holiday types to be an array" do
    public_holiday = public_holidays(:juan_santamaria_day)
    public_holiday.holiday_types = "Public"

    assert_not public_holiday.valid?
    assert_includes public_holiday.errors[:holiday_types], "must be an array"
  end

  test "allows nil subdivision codes" do
    public_holiday = public_holidays(:juan_santamaria_day)
    public_holiday.subdivision_codes = nil

    assert public_holiday.valid?
  end

  test "requires subdivision codes to be an array or nil" do
    public_holiday = public_holidays(:juan_santamaria_day)
    public_holiday.subdivision_codes = "CR-SJ"

    assert_not public_holiday.valid?
    assert_includes public_holiday.errors[:subdivision_codes], "must be an array or nil"
  end

  test "filters holidays using a normalized country code" do
    results = PublicHoliday.for_country(" cr ")

    assert_includes results, public_holidays(:juan_santamaria_day)
    assert_includes results, public_holidays(:independence_day)
  end

  test "orders holidays chronologically" do
    results = PublicHoliday.chronological

    assert_operator results.index(public_holidays(:juan_santamaria_day)),
                    :<,
                    results.index(public_holidays(:independence_day))
  end
end
