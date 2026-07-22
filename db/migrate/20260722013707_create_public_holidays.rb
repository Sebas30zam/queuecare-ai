class CreatePublicHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :public_holidays do |t|
      t.date :date, null: false
      t.string :name, null: false
      t.string :country_code, null: false
      t.boolean :national_holiday, null: false, default: false
      t.jsonb :subdivision_codes
      t.jsonb :holiday_types, null: false, default: []

      t.timestamps
    end

    add_index :public_holidays,
              %i[country_code date name],
              unique: true,
              name: "index_public_holidays_on_country_date_and_name"

    add_check_constraint :public_holidays,
                         "char_length(country_code) = 2",
                         name: "public_holidays_country_code_length"

    add_check_constraint :public_holidays,
                         "jsonb_typeof(holiday_types) = 'array'",
                         name: "public_holidays_holiday_types_array"

    add_check_constraint :public_holidays,
                         "subdivision_codes IS NULL OR jsonb_typeof(subdivision_codes) = 'array'",
                         name: "public_holidays_subdivision_codes_array"
  end
end
