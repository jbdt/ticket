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

ActiveRecord::Schema.define(version: 2025_03_14_081141) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entries", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.integer "ticket_number"
    t.integer "user_ticket_number"
    t.string "code", null: false
    t.string "entry_type", null: false
    t.bigint "user_id", null: false
    t.text "comments"
    t.string "status", default: "created", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "scanned", default: []
    t.boolean "redeemed"
    t.boolean "paid", default: true
    t.index ["code"], name: "index_entries_on_code", unique: true
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "alias_code"
    t.string "email"
    t.string "password_digest"
    t.boolean "admin", default: false, null: false
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "entries", "users"
end
