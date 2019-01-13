# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_01_13_184757) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games_genres", id: false, force: :cascade do |t|
    t.integer "game_id"
    t.integer "genre_id"
    t.index ["game_id"], name: "index_games_genres_on_game_id"
    t.index ["genre_id"], name: "index_games_genres_on_genre_id"
  end

  create_table "genres", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "platforms", force: :cascade do |t|
    t.text "name", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "release_developers", force: :cascade do |t|
    t.bigint "release_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_release_developers_on_company_id"
    t.index ["release_id"], name: "index_release_developers_on_release_id"
  end

  create_table "release_publishers", force: :cascade do |t|
    t.bigint "release_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_release_publishers_on_company_id"
    t.index ["release_id"], name: "index_release_publishers_on_release_id"
  end

  create_table "release_purchases", force: :cascade do |t|
    t.bigint "release_id", null: false
    t.bigint "user_id", null: false
    t.text "comment", default: "", null: false
    t.date "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id"], name: "index_release_purchases_on_release_id"
    t.index ["user_id"], name: "index_release_purchases_on_user_id"
  end

  create_table "releases", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.bigint "platform_id", null: false
    t.bigint "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_releases_on_game_id"
    t.index ["platform_id"], name: "index_releases_on_platform_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "username", null: false
    t.text "bio", default: "", null: false
    t.integer "role", default: 0, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "release_developers", "companies", on_delete: :cascade
  add_foreign_key "release_developers", "releases", on_delete: :cascade
  add_foreign_key "release_publishers", "companies", on_delete: :cascade
  add_foreign_key "release_publishers", "releases", on_delete: :cascade
  add_foreign_key "release_purchases", "releases", on_delete: :cascade
  add_foreign_key "release_purchases", "users", on_delete: :cascade
  add_foreign_key "releases", "games", on_delete: :cascade
  add_foreign_key "releases", "platforms", on_delete: :cascade
end
