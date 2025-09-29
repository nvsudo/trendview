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

ActiveRecord::Schema[8.0].define(version: 2025_09_29_164143) do
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
    t.index ["active"], name: "index_users_on_active"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "account_snapshots", "trading_accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "trades", "securities"
  add_foreign_key "trades", "trading_accounts"
  add_foreign_key "trades", "users"
  add_foreign_key "trading_accounts", "users"
  add_foreign_key "user_stock_analyses", "securities"
  add_foreign_key "user_stock_analyses", "users"
end
