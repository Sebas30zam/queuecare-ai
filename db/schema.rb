# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_22_063709) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "daily_sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_number", default: 0, null: false
    t.bigint "queue_service_id", null: false
    t.date "sequence_date", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_service_id", "sequence_date"], name: "index_daily_sequences_on_queue_service_id_and_sequence_date", unique: true
    t.index ["queue_service_id"], name: "index_daily_sequences_on_queue_service_id"
  end

  create_table "queue_services", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "estimated_attention_minutes"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_queue_services_on_active"
    t.index ["code"], name: "index_queue_services_on_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "satisfaction_surveys", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.datetime "submitted_at"
    t.bigint "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_satisfaction_surveys_on_ticket_id", unique: true
  end

  create_table "service_windows", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "queue_service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_service_windows_on_active"
    t.index ["code"], name: "index_service_windows_on_code", unique: true
    t.index ["queue_service_id"], name: "index_service_windows_on_queue_service_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "assigned_agent_id"
    t.string "assistance_type"
    t.datetime "called_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "customer_identifier"
    t.string "customer_name"
    t.integer "daily_sequence", null: false
    t.datetime "finished_at"
    t.string "intake_source", default: "assisted", null: false
    t.datetime "no_show_at"
    t.string "priority", null: false
    t.integer "priority_weight", null: false
    t.bigint "queue_service_id", null: false
    t.text "request_description"
    t.date "sequence_date", null: false
    t.bigint "service_window_id"
    t.datetime "started_at"
    t.string "status", null: false
    t.string "survey_token", null: false
    t.string "ticket_number", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_agent_id"], name: "index_tickets_on_assigned_agent_id"
    t.index ["assistance_type"], name: "index_tickets_on_assistance_type"
    t.index ["created_by_id"], name: "index_tickets_on_created_by_id"
    t.index ["intake_source"], name: "index_tickets_on_intake_source"
    t.index ["priority"], name: "index_tickets_on_priority"
    t.index ["queue_service_id"], name: "index_tickets_on_queue_service_id"
    t.index ["service_window_id"], name: "index_tickets_on_service_window_id"
    t.index ["status"], name: "index_tickets_on_status"
    t.index ["survey_token"], name: "index_tickets_on_survey_token", unique: true
    t.index ["ticket_number", "sequence_date"], name: "index_tickets_on_ticket_number_and_sequence_date", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "daily_sequences", "queue_services"
  add_foreign_key "satisfaction_surveys", "tickets"
  add_foreign_key "service_windows", "queue_services"
  add_foreign_key "tickets", "queue_services"
  add_foreign_key "tickets", "service_windows"
  add_foreign_key "tickets", "users", column: "assigned_agent_id"
  add_foreign_key "tickets", "users", column: "created_by_id"
  add_foreign_key "users", "roles"
end
