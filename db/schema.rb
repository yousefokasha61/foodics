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

ActiveRecord::Schema[8.0].define(version: 2026_02_08_004504) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "transactions", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.bigint "webhook_id", null: false
    t.string "bank", null: false
    t.string "reference", null: false
    t.bigint "amount_cents", null: false
    t.date "transaction_date", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank", "reference"], name: "index_transactions_on_bank_and_reference", unique: true
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["wallet_id", "transaction_date"], name: "index_transactions_on_wallet_id_and_transaction_date"
    t.index ["wallet_id"], name: "index_transactions_on_wallet_id"
    t.index ["webhook_id"], name: "index_transactions_on_webhook_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_number", null: false
    t.bigint "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_wallets_on_account_number", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.string "bank", null: false
    t.text "raw_payload", null: false
    t.string "status", default: "PENDING", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "processing_errors", default: [], null: false
    t.index ["status"], name: "index_webhooks_on_status"
    t.index ["wallet_id", "status"], name: "index_webhooks_on_wallet_id_and_status"
    t.index ["wallet_id"], name: "index_webhooks_on_wallet_id"
  end

  add_foreign_key "transactions", "wallets"
  add_foreign_key "transactions", "webhooks"
  add_foreign_key "webhooks", "wallets"
end
