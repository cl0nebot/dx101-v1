# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140511215158) do

  create_table "crypto_addresses", force: true do |t|
    t.integer  "user_id"
    t.string   "address"
    t.string   "currency"
    t.string   "label"
    t.datetime "hide_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crypto_addresses", ["user_id"], name: "index_crypto_addresses_on_user_id", using: :btree

  create_table "crypto_deposits", force: true do |t|
    t.integer  "crypto_address_id"
    t.string   "txid"
    t.integer  "status"
    t.integer  "confirmations"
    t.integer  "retries"
    t.decimal  "amount_subunit",    precision: 65, scale: 10
    t.datetime "complete_at"
    t.datetime "canceled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crypto_deposits", ["crypto_address_id"], name: "index_crypto_deposits_on_crypto_address_id", using: :btree

  create_table "crypto_withdraw_batches", force: true do |t|
    t.string   "txid"
    t.string   "currency"
    t.decimal  "fee_subunit", precision: 65, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crypto_withdraws", force: true do |t|
    t.integer  "user_id"
    t.integer  "crypto_withdraw_batch_id"
    t.string   "address"
    t.integer  "status"
    t.string   "currency"
    t.decimal  "amount_subunit",           precision: 65, scale: 10
    t.decimal  "fee_subunit",              precision: 65, scale: 10
    t.datetime "complete_at"
    t.datetime "canceled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crypto_withdraws", ["crypto_withdraw_batch_id"], name: "index_crypto_withdraws_on_crypto_withdraw_batch_id", using: :btree
  add_index "crypto_withdraws", ["user_id"], name: "index_crypto_withdraws_on_user_id", using: :btree

  create_table "email_addresses", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "verification_code"
    t.datetime "verified_at"
    t.datetime "primary_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "finance_accounts", force: true do |t|
    t.integer  "user_id"
    t.integer  "agent_id"
    t.integer  "vendor"
    t.integer  "category"
    t.string   "name"
    t.string   "type"
    t.boolean  "contra"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finance_accounts", ["agent_id"], name: "index_finance_accounts_on_agent_id", using: :btree
  add_index "finance_accounts", ["user_id"], name: "index_finance_accounts_on_user_id", using: :btree

  create_table "finance_amounts", force: true do |t|
    t.string  "type"
    t.integer "account_id"
    t.integer "transaction_id"
    t.string  "currency"
    t.decimal "amount_subunit", precision: 65, scale: 10
  end

  add_index "finance_amounts", ["account_id"], name: "index_finance_amounts_on_account_id", using: :btree
  add_index "finance_amounts", ["transaction_id"], name: "index_finance_amounts_on_transaction_id", using: :btree

  create_table "finance_transactions", force: true do |t|
    t.integer  "transaction_type"
    t.integer  "related_id"
    t.string   "related_type"
    t.datetime "created_at",       default: '2014-06-07 18:39:50', null: false
  end

  add_index "finance_transactions", ["related_id", "related_type"], name: "index_finance_transactions_on_related_id_and_related_type", using: :btree

  create_table "roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["user_id"], name: "index_roles_on_user_id", using: :btree

  create_table "session_histories", force: true do |t|
    t.integer  "user_id"
    t.integer  "related_id"
    t.string   "related_type"
    t.integer  "status"
    t.string   "ip_address"
    t.datetime "created_at"
  end

  add_index "session_histories", ["related_id", "related_type"], name: "index_session_histories_on_related_id_and_related_type", using: :btree
  add_index "session_histories", ["user_id"], name: "index_session_histories_on_user_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "settings", force: true do |t|
    t.integer  "user_id"
    t.integer  "setting_type"
    t.text     "meta"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["user_id"], name: "index_settings_on_user_id", using: :btree

  create_table "trade_transactions", force: true do |t|
    t.integer  "source_id"
    t.integer  "target_id"
    t.string   "rate_currency"
    t.string   "quantity_currency"
    t.string   "source_fee_currency"
    t.string   "target_fee_currency"
    t.decimal  "rate_subunit",        precision: 65, scale: 10
    t.decimal  "price_subunit",       precision: 65, scale: 10
    t.decimal  "quantity_subunit",    precision: 65, scale: 10
    t.decimal  "source_fee_subunit",  precision: 65, scale: 10
    t.decimal  "target_fee_subunit",  precision: 65, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trade_transactions", ["source_id"], name: "index_trade_transactions_on_source_id", using: :btree
  add_index "trade_transactions", ["target_id"], name: "index_trade_transactions_on_target_id", using: :btree

  create_table "trades", force: true do |t|
    t.integer  "user_id"
    t.integer  "transfer_type"
    t.integer  "trade_type"
    t.integer  "status"
    t.string   "rate_currency"
    t.string   "quantity_currency"
    t.decimal  "rate_subunit",            precision: 65, scale: 10
    t.decimal  "stop_subunit",            precision: 65, scale: 10
    t.decimal  "quantity_subunit",        precision: 65, scale: 10
    t.decimal  "quantity_filled_subunit", precision: 65, scale: 10
    t.decimal  "fee",                     precision: 65, scale: 10
    t.boolean  "basic"
    t.boolean  "fok"
    t.boolean  "ioc"
    t.datetime "processed_at"
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trades", ["user_id"], name: "index_trades_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password"
    t.string   "password_reset_code"
    t.string   "mfa_secret"
    t.string   "country_residence"
    t.string   "country_citizenship"
    t.datetime "birth_date"
    t.datetime "tos_agreed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: true do |t|
    t.integer  "user_id"
    t.integer  "item_id",    null: false
    t.string   "item_type",  null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.string   "ip_address"
    t.string   "user_agent"
    t.datetime "created_at"
  end

  add_index "versions", ["item_id", "item_type"], name: "index_versions_on_item_id_and_item_type", using: :btree
  add_index "versions", ["user_id"], name: "index_versions_on_user_id", using: :btree

end
