class ServiceWindow < ApplicationRecord
  belongs_to :queue_service

  has_many :tickets, dependent: :restrict_with_exception

  before_validation :normalize_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end
