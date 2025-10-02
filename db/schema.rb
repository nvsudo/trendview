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

ActiveRecord::Schema[8.0].define(version: 2025_10_02_162613) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_status", ["active", "inactive", "syncing", "error"]
  create_enum "conviction_level", ["low", "medium", "high", "very_high"]
  create_enum "security_type", ["stock", "future", "option", "etf", "mutual_fund", "currency", "commodity"]
  create_enum "trade_status", ["open", "closed", "partial"]
  create_enum "trade_timeframe", ["intraday", "swing", "positional", "long_term"]
  create_enum "trade_type", ["buy", "sell"]
  create_enum "trading_account_type", ["personal", "aggressive", "conservative", "family", "retirement"]
  create_enum "user_role", ["trader", "admin"]

  create_table "account_snapshots", force: :cascade do |t|
    t.bigint "trading_account_id", null: false
    t.date "date", null: false
    t.decimal "total_value", precision: 15, scale: 2, null: false
    t.decimal "cash_balance", precision: 15, scale: 2, default: "0.0"
    t.decimal "invested_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "unrealized_pnl", precision: 15, scale: 2, default: "0.0"
    t.decimal "realized_pnl", precision: 15, scale: 2, default: "0.0"
    t.decimal "day_pnl", precision: 12, scale: 2, default: "0.0"
    t.decimal "day_pnl_percent", precision: 8, scale: 4, default: "0.0"
    t.decimal "percent_deployed", precision: 5, scale: 2, default: "0.0"
    t.integer "number_of_positions", default: 0
    t.decimal "portfolio_beta", precision: 6, scale: 4
    t.decimal "max_drawdown", precision: 8, scale: 4
    t.decimal "sharpe_ratio", precision: 6, scale: 4
    t.datetime "synced_at"
    t.string "sync_source", default: "zerodha"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_account_snapshots_on_date"
    t.index ["date"], name: "index_account_snapshots_on_date_desc", order: :desc
    t.index ["synced_at"], name: "index_account_snapshots_on_synced_at"
    t.index ["trading_account_id", "date"], name: "index_account_snapshots_on_trading_account_id_and_date", unique: true
    t.index ["trading_account_id"], name: "index_account_snapshots_on_trading_account_id"
  end

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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "holding_sections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0
    t.string "color", default: "#6B7280"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_holding_sections_on_user_id_and_name", unique: true
    t.index ["user_id", "position"], name: "index_holding_sections_on_user_id_and_position"
    t.index ["user_id"], name: "index_holding_sections_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trading_account_id", null: false
    t.bigint "security_id", null: false
    t.integer "quantity", null: false
    t.decimal "average_price", precision: 10, scale: 2, null: false
    t.string "position_type", default: "long", null: false
    t.decimal "unrealized_pnl", precision: 12, scale: 2, default: "0.0"
    t.datetime "last_updated"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "holding_section_id"
    t.integer "generation", default: 1, null: false
    t.string "status", default: "open", null: false
    t.datetime "opened_at", null: false
    t.index ["closed_at"], name: "index_positions_on_closed_at"
    t.index ["generation"], name: "index_positions_on_generation"
    t.index ["holding_section_id"], name: "index_positions_on_holding_section_id"
    t.index ["security_id"], name: "index_positions_on_security_id"
    t.index ["status"], name: "index_positions_on_status"
    t.index ["trading_account_id"], name: "index_positions_on_trading_account_id"
    t.index ["user_id", "holding_section_id"], name: "index_positions_on_user_id_and_holding_section_id"
    t.index ["user_id", "position_type"], name: "index_positions_on_user_id_and_position_type"
    t.index ["user_id", "status"], name: "index_positions_on_user_id_and_status"
    t.index ["user_id", "trading_account_id", "security_id", "generation"], name: "idx_position_unique_identity", unique: true
    t.index ["user_id", "trading_account_id", "security_id", "status"], name: "idx_one_open_position_per_security", unique: true, where: "((status)::text = 'open'::text)"
    t.index ["user_id"], name: "index_positions_on_user_id"
  end

  create_table "securities", force: :cascade do |t|
    t.string "symbol", null: false
    t.string "nse_symbol"
    t.string "bse_symbol"
    t.string "company_name", null: false
    t.string "exchange", null: false
    t.string "segment"
    t.enum "security_type", default: "stock", enum_type: "security_type"
    t.string "sector"
    t.string "industry"
    t.decimal "last_price", precision: 10, scale: 2
    t.decimal "day_change", precision: 10, scale: 2
    t.decimal "day_change_percent", precision: 8, scale: 4
    t.decimal "week_52_high", precision: 10, scale: 2
    t.decimal "week_52_low", precision: 10, scale: 2
    t.bigint "volume"
    t.decimal "avg_volume", precision: 15, scale: 2
    t.decimal "market_cap", precision: 15, scale: 2
    t.integer "lot_size", default: 1
    t.string "data_provider", default: "zerodha"
    t.datetime "last_updated"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_securities_on_active"
    t.index ["exchange"], name: "index_securities_on_exchange"
    t.index ["last_updated"], name: "index_securities_on_last_updated"
    t.index ["nse_symbol"], name: "index_securities_on_nse_symbol"
    t.index ["sector"], name: "index_securities_on_sector"
    t.index ["security_type"], name: "index_securities_on_security_type"
    t.index ["symbol", "exchange"], name: "index_securities_on_symbol_and_exchange", unique: true
    t.index ["symbol"], name: "index_securities_on_symbol"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trading_account_id", null: false
    t.bigint "security_id", null: false
    t.enum "trade_type", default: "buy", enum_type: "trade_type"
    t.integer "quantity", null: false
    t.decimal "entry_price", precision: 10, scale: 2, null: false
    t.decimal "exit_price", precision: 10, scale: 2
    t.datetime "entry_date", null: false
    t.datetime "exit_date"
    t.decimal "gross_pnl", precision: 12, scale: 2
    t.decimal "brokerage", precision: 8, scale: 2, default: "0.0"
    t.decimal "taxes", precision: 8, scale: 2, default: "0.0"
    t.decimal "net_pnl", precision: 12, scale: 2
    t.string "strategy"
    t.enum "timeframe", default: "swing", enum_type: "trade_timeframe"
    t.enum "status", default: "open", enum_type: "trade_status"
    t.decimal "planned_stop_loss", precision: 10, scale: 2
    t.decimal "planned_target", precision: 10, scale: 2
    t.decimal "risk_amount", precision: 10, scale: 2
    t.decimal "risk_reward_ratio", precision: 6, scale: 2
    t.integer "entry_stage"
    t.decimal "entry_rs_rank", precision: 4, scale: 1
    t.integer "setup_quality", default: 3
    t.string "zerodha_order_id"
    t.string "zerodha_trade_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_date"], name: "index_trades_on_entry_date"
    t.index ["exit_date"], name: "index_trades_on_exit_date"
    t.index ["security_id"], name: "index_trades_on_security_id"
    t.index ["status"], name: "index_trades_on_status"
    t.index ["strategy"], name: "index_trades_on_strategy"
    t.index ["trade_type"], name: "index_trades_on_trade_type"
    t.index ["trading_account_id"], name: "index_trades_on_trading_account_id"
    t.index ["user_id", "entry_date"], name: "index_trades_on_user_id_and_entry_date"
    t.index ["user_id", "status"], name: "index_trades_on_user_id_and_status"
    t.index ["user_id"], name: "index_trades_on_user_id"
    t.index ["zerodha_trade_id"], name: "index_trades_on_zerodha_trade_id", unique: true, where: "(zerodha_trade_id IS NOT NULL)"
  end

  create_table "trading_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "zerodha_user_id", null: false
    t.string "account_name", null: false
    t.enum "account_type", default: "personal", enum_type: "trading_account_type"
    t.boolean "is_primary", default: false
    t.text "api_credentials"
    t.enum "status", default: "active", enum_type: "account_status"
    t.datetime "last_synced_at"
    t.text "sync_error_message"
    t.string "broker_name", default: "Zerodha"
    t.string "account_number"
    t.jsonb "account_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_type"], name: "index_trading_accounts_on_account_type"
    t.index ["status"], name: "index_trading_accounts_on_status"
    t.index ["user_id", "is_primary"], name: "index_trading_accounts_on_user_id_and_is_primary"
    t.index ["user_id"], name: "index_trading_accounts_on_user_id"
    t.index ["zerodha_user_id"], name: "index_trading_accounts_on_zerodha_user_id", unique: true
  end

  create_table "user_stock_analyses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "security_id", null: false
    t.integer "user_stage"
    t.decimal "user_rs_rank", precision: 4, scale: 1
    t.text "user_notes"
    t.string "analysis_strategy"
    t.integer "setup_quality_rating"
    t.enum "conviction_level", default: "medium", enum_type: "conviction_level"
    t.decimal "target_entry_price", precision: 10, scale: 2
    t.decimal "target_exit_price", precision: 10, scale: 2
    t.decimal "stop_loss_price", precision: 10, scale: 2
    t.datetime "last_updated_by_user"
    t.integer "analysis_version", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_strategy"], name: "index_user_stock_analyses_on_analysis_strategy"
    t.index ["last_updated_by_user"], name: "index_user_stock_analyses_on_last_updated_by_user"
    t.index ["security_id"], name: "index_user_stock_analyses_on_security_id"
    t.index ["user_id", "security_id"], name: "index_user_stock_analyses_on_user_and_security", unique: true
    t.index ["user_id"], name: "index_user_stock_analyses_on_user_id"
    t.index ["user_rs_rank"], name: "index_user_stock_analyses_on_user_rs_rank"
    t.index ["user_stage"], name: "index_user_stock_analyses_on_user_stage"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number"
    t.date "date_of_birth"
    t.string "default_currency", default: "INR"
    t.string "timezone", default: "Asia/Kolkata"
    t.boolean "ai_insights_enabled", default: true
    t.enum "role", default: "trader", enum_type: "user_role"
    t.boolean "active", default: true
    t.datetime "last_login_at"
    t.datetime "onboarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "onboarding_step", default: "profile"
    t.datetime "onboarding_started_at"
    t.datetime "onboarding_completed_at"
    t.boolean "has_trading_profile", default: false
    t.boolean "has_trading_account", default: false
    t.boolean "has_initial_data", default: false
    t.jsonb "onboarding_data", default: {}
    t.string "onboarding_data_path"
    t.index ["active"], name: "index_users_on_active"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["onboarding_completed_at"], name: "index_users_on_onboarding_completed_at"
    t.index ["onboarding_data"], name: "index_users_on_onboarding_data", using: :gin
    t.index ["onboarding_step"], name: "index_users_on_onboarding_step"
  end

  add_foreign_key "account_snapshots", "trading_accounts"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "holding_sections", "users"
  add_foreign_key "positions", "holding_sections"
  add_foreign_key "positions", "securities"
  add_foreign_key "positions", "trading_accounts"
  add_foreign_key "positions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "trades", "securities"
  add_foreign_key "trades", "trading_accounts"
  add_foreign_key "trades", "users"
  add_foreign_key "trading_accounts", "users"
  add_foreign_key "user_stock_analyses", "securities"
  add_foreign_key "user_stock_analyses", "users"
end
