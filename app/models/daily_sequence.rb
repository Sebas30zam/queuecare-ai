class DailySequence < ApplicationRecord
  belongs_to :queue_service

  validates :sequence_date, presence: true
  validates :current_number,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }
  validates :sequence_date,
            uniqueness: { scope: :queue_service_id }
end
