module PublicHolidays
    class SyncService
      Result = Struct.new(
        :created_count,
        :updated_count,
        :unchanged_count,
        :deleted_count,
        :errors,
        keyword_init: true
      ) do
        def success?
          errors.empty?
        end
      end

      def initialize(
        client: NagerDateClient.new,
        default_country_code:
          Rails.application.config.x.public_holidays.country_code
      )
        @client = client
        @default_country_code = default_country_code
      end

      def call(year:, country_code: nil)
        normalized_year = normalize_year(year)
        normalized_country_code = normalize_country_code(
          country_code || default_country_code
        )

        holidays = client.fetch(
          year: normalized_year,
          country_code: normalized_country_code
        )

        synchronize(
          holidays: holidays,
          year: normalized_year,
          country_code: normalized_country_code
        )
      rescue ArgumentError, NagerDateClient::Error => error
        failure(error.message)
      rescue ActiveRecord::ActiveRecordError => error
        failure("Unable to synchronize public holidays: #{error.message}")
      end

      private

      attr_reader :client, :default_country_code

      def synchronize(holidays:, year:, country_code:)
        counts = {
          created_count: 0,
          updated_count: 0,
          unchanged_count: 0,
          deleted_count: 0
        }

        PublicHoliday.transaction do
          synchronized_ids = holidays.map do |attributes|
            synchronize_holiday(attributes, counts: counts)
          end

          stale_holidays = holidays_for(
            year: year,
            country_code: country_code
          ).where.not(id: synchronized_ids)

          counts[:deleted_count] = stale_holidays.delete_all
        end

        Result.new(**counts, errors: [])
      end

      def synchronize_holiday(attributes, counts:)
        public_holiday = PublicHoliday.find_or_initialize_by(
          country_code: attributes.fetch(:country_code),
          date: attributes.fetch(:date),
          name: attributes.fetch(:name)
        )

        if public_holiday.new_record?
          public_holiday.assign_attributes(attributes)
          public_holiday.save!
          counts[:created_count] += 1
        elsif public_holiday.attributes.slice(
          "national_holiday",
          "subdivision_codes",
          "holiday_types"
        ) == comparable_attributes(attributes)
          counts[:unchanged_count] += 1
        else
          public_holiday.update!(attributes)
          counts[:updated_count] += 1
        end

        public_holiday.id
      end

      def comparable_attributes(attributes)
        {
          "national_holiday" => attributes.fetch(:national_holiday),
          "subdivision_codes" => attributes[:subdivision_codes],
          "holiday_types" => attributes.fetch(:holiday_types)
        }
      end

      def holidays_for(year:, country_code:)
        PublicHoliday.for_country(country_code).where(
          date: Date.new(year).all_year
        )
      end

      def normalize_year(year)
        normalized_year = Integer(year, exception: false)

        return normalized_year if normalized_year&.between?(1, 9999)

        raise ArgumentError, "year must be an integer between 1 and 9999"
      end

      def normalize_country_code(country_code)
        normalized_country_code = country_code.to_s.strip.upcase

        return normalized_country_code if normalized_country_code.match?(
          /\A[A-Z]{2}\z/
        )

        raise ArgumentError, "country_code must contain exactly two letters"
      end

      def failure(message)
        Result.new(
          created_count: 0,
          updated_count: 0,
          unchanged_count: 0,
          deleted_count: 0,
          errors: [ message ]
        )
      end
    end
end
