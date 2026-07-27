Rails.application.config.x.public_holidays.base_url =
  ENV.fetch("PUBLIC_HOLIDAYS_API_BASE_URL", "https://date.nager.at/api/v4")

Rails.application.config.x.public_holidays.country_code =
  ENV.fetch("PUBLIC_HOLIDAYS_COUNTRY_CODE", "CR")

Rails.application.config.x.public_holidays.open_timeout =
  ENV.fetch("PUBLIC_HOLIDAYS_OPEN_TIMEOUT", 5).to_i

Rails.application.config.x.public_holidays.read_timeout =
  ENV.fetch("PUBLIC_HOLIDAYS_READ_TIMEOUT", 10).to_i
