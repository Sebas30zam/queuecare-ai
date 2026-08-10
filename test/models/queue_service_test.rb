require "test_helper"

class QueueServiceTest < ActiveSupport::TestCase
  test "estimated attention minutes is required" do
    queue_service = QueueService.new(
      name: "Test Service",
      code: "TST",
      active: true,
      estimated_attention_minutes: nil
    )

    assert_not queue_service.valid?
    assert queue_service.errors[:estimated_attention_minutes].present?
  end

  test "estimated attention minutes must be positive" do
    queue_service = QueueService.new(
      name: "Test Service",
      code: "TST",
      active: true,
      estimated_attention_minutes: 0
    )

    assert_not queue_service.valid?
    assert queue_service.errors[:estimated_attention_minutes].present?
  end
end
