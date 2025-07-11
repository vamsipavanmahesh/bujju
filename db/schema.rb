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

ActiveRecord::Schema[8.0].define(version: 2025_06_07_092716) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "connections", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone_number", null: false
    t.string "relationship", default: "friend", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_connections_on_user_id"
  end

  create_table "onboarding", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "notification_time_setting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_onboarding_on_user_id", unique: true
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.time "notification_time"
    t.string "timezone", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "avatar_url"
    t.string "provider", null: false
    t.string "provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "provider_id"], name: "index_users_on_provider_and_provider_id", unique: true
  end

  add_foreign_key "connections", "users"
  add_foreign_key "onboarding", "users"
  add_foreign_key "user_preferences", "users"
end
