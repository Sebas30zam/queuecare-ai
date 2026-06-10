require "test_helper"

class DailySequenceTest < ActiveSupport::TestCase
  test "is valid with a service date and non-negative current number" do
    sequence = build_sequence

    assert sequence.valid?
  end

  test "requires a sequence date" do
    sequence = build_sequence(sequence_date: nil)

    assert_not sequence.valid?
    assert sequence.errors[:sequence_date].any?
  end

  test "requires a current number" do
    sequence = build_sequence(current_number: nil)

    assert_not sequence.valid?
    assert sequence.errors[:current_number].any?
  end

  test "current number must be a non-negative integer" do
    negative_sequence = build_sequence(current_number: -1)
    decimal_sequence = build_sequence(current_number: 1.5)

    assert_not negative_sequence.valid?
    assert negative_sequence.errors[:current_number].any?

    assert_not decimal_sequence.valid?
    assert decimal_sequence.errors[:current_number].any?
  end

  test "service and sequence date combination must be unique" do
    sequence = build_sequence(
      queue_service: queue_services(:admissions),
      sequence_date: Date.new(2026, 6, 9)
    )

    assert_not sequence.valid?
    assert sequence.errors[:sequence_date].any?
  end

  test "same sequence date is allowed for a different service" do
    sequence = build_sequence(
      queue_service: queue_services(:finance),
      sequence_date: Date.new(2026, 6, 10)
    )

    assert sequence.valid?
  end

  test "daily sequence fixtures are valid" do
    assert daily_sequences(:admissions_today).valid?
    assert daily_sequences(:finance_today).valid?
  end

  private

  def build_sequence(attributes = {})
    DailySequence.new(
      {
        queue_service: queue_services(:admissions),
        sequence_date: Date.new(2026, 6, 10),
        current_number: 0
      }.merge(attributes)
    )
  end
end
