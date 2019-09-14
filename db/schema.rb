# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_14_185512) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wikidata_id"
    t.index ["wikidata_id"], name: "index_companies_on_wikidata_id", unique: true
  end

  create_table "engines", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wikidata_id"
    t.index ["wikidata_id"], name: "index_engines_on_wikidata_id", unique: true
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "eventable_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "event_category", null: false
    t.jsonb "differences"
    t.string "eventable_type"
    t.index ["eventable_id", "eventable_type", "user_id"], name: "index_events_on_id_type_and_user_id"
    t.index ["eventable_id"], name: "index_events_on_eventable_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "external_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "account_type", null: false
    t.bigint "steam_id"
    t.text "steam_profile_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_id"], name: "index_external_accounts_on_steam_id", unique: true
    t.index ["user_id", "account_type"], name: "index_external_accounts_on_user_id_and_account_type", unique: true
    t.index ["user_id"], name: "index_external_accounts_on_user_id"
  end

  create_table "favorite_games", force: :cascade do |t|
    t.bigint "game_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_favorite_games_on_game_id"
    t.index ["user_id", "game_id"], name: "index_favorite_games_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_favorite_games_on_user_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "game_developers", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_game_developers_on_company_id"
    t.index ["game_id"], name: "index_game_developers_on_game_id"
  end

  create_table "game_engines", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "engine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["engine_id"], name: "index_game_engines_on_engine_id"
    t.index ["game_id", "engine_id"], name: "index_game_engines_on_game_id_and_engine_id", unique: true
    t.index ["game_id"], name: "index_game_engines_on_game_id"
  end

  create_table "game_genres", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "genre_id"], name: "index_game_genres_on_game_id_and_genre_id", unique: true
    t.index ["game_id"], name: "index_game_genres_on_game_id"
    t.index ["genre_id"], name: "index_game_genres_on_genre_id"
  end

  create_table "game_platforms", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "platform_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "platform_id"], name: "index_game_platforms_on_game_id_and_platform_id", unique: true
    t.index ["game_id"], name: "index_game_platforms_on_game_id"
    t.index ["platform_id"], name: "index_game_platforms_on_platform_id"
  end

  create_table "game_publishers", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_game_publishers_on_company_id"
    t.index ["game_id"], name: "index_game_publishers_on_game_id"
  end

  create_table "game_purchase_platforms", force: :cascade do |t|
    t.bigint "game_purchase_id", null: false
    t.bigint "platform_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_purchase_id", "platform_id"], name: "index_game_purchase_platforms_on_game_purchase_and_platform", unique: true
    t.index ["game_purchase_id"], name: "index_game_purchase_platforms_on_game_purchase_id"
    t.index ["platform_id"], name: "index_game_purchase_platforms_on_platform_id"
  end

  create_table "game_purchases", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "user_id", null: false
    t.text "comments", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rating"
    t.integer "completion_status"
    t.date "start_date"
    t.date "completion_date"
    t.decimal "hours_played", precision: 10, scale: 1
    t.index ["game_id"], name: "index_game_purchases_on_game_id"
    t.index ["user_id"], name: "index_game_purchases_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "series_id"
    t.bigint "wikidata_id"
    t.text "pcgamingwiki_id"
    t.integer "steam_app_id"
    t.text "mobygames_id"
    t.date "release_date"
    t.index ["mobygames_id"], name: "index_games_on_mobygames_id", unique: true
    t.index ["series_id"], name: "index_games_on_series_id"
    t.index ["steam_app_id"], name: "index_games_on_steam_app_id", unique: true
    t.index ["wikidata_id"], name: "index_games_on_wikidata_id", unique: true
  end

  create_table "genres", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wikidata_id"
    t.index ["wikidata_id"], name: "index_genres_on_wikidata_id", unique: true
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.text "name", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wikidata_id"
    t.index ["wikidata_id"], name: "index_platforms_on_wikidata_id", unique: true
  end

  create_table "relationships", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_relationships_on_follower_id"
  end

  create_table "series", force: :cascade do |t|
    t.text "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wikidata_id"
    t.index ["wikidata_id"], name: "index_series_on_wikidata_id", unique: true
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
    t.string "slug"
    t.integer "privacy", default: 0, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "wikidata_blocklists", force: :cascade do |t|
    t.bigint "wikidata_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "name", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_wikidata_blocklists_on_user_id"
    t.index ["wikidata_id"], name: "index_wikidata_blocklists_on_wikidata_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "external_accounts", "users", on_delete: :cascade
  add_foreign_key "favorite_games", "games", on_delete: :cascade
  add_foreign_key "favorite_games", "users", on_delete: :cascade
  add_foreign_key "game_developers", "companies", on_delete: :cascade
  add_foreign_key "game_developers", "games", on_delete: :cascade
  add_foreign_key "game_engines", "engines", on_delete: :cascade
  add_foreign_key "game_engines", "games", on_delete: :cascade
  add_foreign_key "game_genres", "games", on_delete: :cascade
  add_foreign_key "game_genres", "genres", on_delete: :cascade
  add_foreign_key "game_platforms", "games", on_delete: :cascade
  add_foreign_key "game_platforms", "platforms", on_delete: :cascade
  add_foreign_key "game_publishers", "companies", on_delete: :cascade
  add_foreign_key "game_publishers", "games", on_delete: :cascade
  add_foreign_key "game_purchase_platforms", "game_purchases", on_delete: :cascade
  add_foreign_key "game_purchase_platforms", "platforms", on_delete: :cascade
  add_foreign_key "game_purchases", "games", on_delete: :cascade
  add_foreign_key "game_purchases", "users", on_delete: :cascade
  add_foreign_key "games", "series", on_delete: :nullify
  add_foreign_key "relationships", "users", column: "followed_id"
  add_foreign_key "relationships", "users", column: "follower_id"
  add_foreign_key "wikidata_blocklists", "users"
end
