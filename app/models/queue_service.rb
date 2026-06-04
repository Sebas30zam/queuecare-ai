class QueueService < ApplicationRecord
  before_validation :normalize_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :estimated_attention_minutes,
            numericality: { greater_than: 0 },
            allow_nil: true

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end
