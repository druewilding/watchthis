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

ActiveRecord::Schema[8.1].define(version: 2026_06_28_105912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "list_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "list_id", null: false
    t.bigint "media_id", null: false
    t.text "notes"
    t.integer "position"
    t.bigint "share_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "watched_at"
    t.index ["list_id", "status", "created_at"], name: "index_list_items_on_list_id_and_status_and_created_at"
    t.index ["list_id"], name: "index_list_items_on_list_id"
    t.index ["media_id"], name: "index_list_items_on_media_id"
    t.index ["share_id"], name: "index_list_items_on_share_id"
  end

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.boolean "is_private", default: true, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_lists_on_user_id"
  end

  create_table "media", force: :cascade do |t|
    t.bigint "added_by_id", null: false
    t.string "author"
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.string "normalized_url", null: false
    t.string "platform", null: false
    t.datetime "published_at"
    t.string "thumbnail_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.string "youtube_id"
    t.index ["added_by_id"], name: "index_media_on_added_by_id"
    t.index ["normalized_url"], name: "index_media_on_normalized_url", unique: true
    t.index ["platform"], name: "index_media_on_platform"
  end

  create_table "shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_user_id", null: false
    t.bigint "media_id", null: false
    t.string "message"
    t.string "status", default: "pending", null: false
    t.bigint "to_user_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "watched_at"
    t.index ["from_user_id", "created_at"], name: "index_shares_on_from_user_id_and_created_at"
    t.index ["from_user_id"], name: "index_shares_on_from_user_id"
    t.index ["media_id"], name: "index_shares_on_media_id"
    t.index ["to_user_id", "status", "created_at"], name: "index_shares_on_to_user_id_and_status_and_created_at"
    t.index ["to_user_id"], name: "index_shares_on_to_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "list_items", "lists"
  add_foreign_key "list_items", "media", column: "media_id"
  add_foreign_key "list_items", "shares"
  add_foreign_key "lists", "users"
  add_foreign_key "media", "users", column: "added_by_id"
  add_foreign_key "shares", "media", column: "media_id"
  add_foreign_key "shares", "users", column: "from_user_id"
  add_foreign_key "shares", "users", column: "to_user_id"
end
