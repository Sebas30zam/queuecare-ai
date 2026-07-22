class PublicHoliday < ApplicationRecord
    validates :date, :name, :country_code, presence: true
    validates :country_code, format: { with: /\A[A-Z]{2}\z/ }
    validates :name, uniqueness: { scope: %i[country_code date] }
    validates :national_holiday, inclusion: { in: [ true, false ] }

    validate :holiday_types_must_be_an_array
    validate :subdivision_codes_must_be_an_array_or_nil

    scope :for_country, lambda { |country_code|
      where(country_code: country_code.to_s.strip.upcase)
    }
    scope :chronological, -> { order(:date, :name) }

    before_validation :normalize_country_code

    private

    def normalize_country_code
      self.country_code = country_code.to_s.strip.upcase.presence
    end

    def holiday_types_must_be_an_array
      return if holiday_types.is_a?(Array)

      errors.add(:holiday_types, "must be an array")
    end

    def subdivision_codes_must_be_an_array_or_nil
      return if subdivision_codes.nil? || subdivision_codes.is_a?(Array)

      errors.add(:subdivision_codes, "must be an array or nil")
    end
end
