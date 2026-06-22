class SatisfactionSurvey < ApplicationRecord
  belongs_to :ticket

  validates :rating,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5
            }

  validates :ticket_id, uniqueness: true
end
