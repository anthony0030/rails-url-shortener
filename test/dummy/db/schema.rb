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

ActiveRecord::Schema[8.1].define(version: 2026_04_23_100000) do
  create_table "rails_url_shortener_ipgeos", force: :cascade do |t|
    t.string "as"
    t.string "asn"
    t.string "asname"
    t.string "backend"
    t.string "city_name"
    t.string "continent_code"
    t.string "continent_name"
    t.float "country_area"
    t.string "country_calling_code"
    t.string "country_capital_name"
    t.string "country_code"
    t.string "country_code_iso3"
    t.string "country_name"
    t.string "country_tld"
    t.datetime "created_at", null: false
    t.string "currency_code"
    t.string "currency_name"
    t.string "district"
    t.string "host_name"
    t.boolean "hosting"
    t.boolean "in_eu"
    t.string "ip"
    t.string "ip_version"
    t.string "isp"
    t.string "languages"
    t.string "latitude"
    t.string "longitude"
    t.boolean "mobile"
    t.string "network"
    t.string "offset"
    t.string "org"
    t.string "provider"
    t.boolean "proxy"
    t.string "region_code"
    t.string "region_name"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.string "utc_offset"
    t.string "zip_code"
  end

  create_table "rails_url_shortener_urls", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "custom_host"
    t.datetime "expires_at"
    t.boolean "forward_query_params"
    t.string "key", limit: 10, null: false
    t.string "kind"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "password_digest"
    t.boolean "paused", default: false, null: false
    t.datetime "starts_at"
    t.boolean "tracked", default: true, null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.index ["owner_type", "owner_id", "kind"], name: "index_urls_on_owner_and_kind"
  end

  create_table "rails_url_shortener_visits", force: :cascade do |t|
    t.boolean "bot"
    t.string "browser"
    t.string "browser_version"
    t.datetime "created_at", null: false
    t.string "ip"
    t.integer "ipgeo_id"
    t.text "meta"
    t.text "params"
    t.string "platform"
    t.string "platform_version"
    t.string "referer", default: ""
    t.datetime "updated_at", null: false
    t.integer "url_id"
    t.string "user_agent"
    t.index ["ipgeo_id"], name: "index_rails_url_shortener_visits_on_ipgeo_id"
    t.index ["url_id"], name: "index_rails_url_shortener_visits_on_url_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
  end
end
