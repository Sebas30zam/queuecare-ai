namespace :public_holidays do
  desc "Synchronize public holidays for a country and year"
  task sync: :environment do
    year = ENV.fetch("YEAR", Date.current.year.to_s)
    country_code = ENV.fetch(
      "COUNTRY_CODE",
      Rails.application.config.x.public_holidays.country_code
    ).to_s.strip.upcase

    result = PublicHolidays::SyncService.new.call(
      year: year,
      country_code: country_code
    )

    unless result.success?
      abort(
        "Public holidays synchronization failed: " \
        "#{result.errors.join(', ')}"
      )
    end

    puts "Public holidays synchronized for #{country_code} in #{year}."
    puts "Created: #{result.created_count}"
    puts "Updated: #{result.updated_count}"
    puts "Unchanged: #{result.unchanged_count}"
    puts "Deleted: #{result.deleted_count}"
  end
end
