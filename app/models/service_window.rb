class ServiceWindow < ApplicationRecord
  belongs_to :queue_service

  before_validation :normalize_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end
