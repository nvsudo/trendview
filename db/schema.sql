-- Ignition Trading Journal Database Schema
-- Apply this SQL directly to your Railway PostgreSQL database

-- Create schema_migrations table for Rails
CREATE TABLE IF NOT EXISTS schema_migrations (
    version character varying NOT NULL PRIMARY KEY
);

-- Create ar_internal_metadata table for Rails
CREATE TABLE IF NOT EXISTS ar_internal_metadata (
    key character varying NOT NULL PRIMARY KEY,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

-- Create enum types first
CREATE TYPE user_role AS ENUM ('individual_trader', 'prop_trader', 'admin');
CREATE TYPE account_type AS ENUM ('individual', 'prop_firm', 'paper_trading');
CREATE TYPE account_status AS ENUM ('active', 'suspended', 'closed');
CREATE TYPE conviction_level AS ENUM ('low', 'medium', 'high', 'very_high');
CREATE TYPE trade_type AS ENUM ('buy', 'sell');
CREATE TYPE trade_timeframe AS ENUM ('intraday', 'swing', 'positional', 'long_term');
CREATE TYPE trade_status AS ENUM ('open', 'closed', 'partial');

-- 1. Users table
CREATE TABLE users (
    id bigserial PRIMARY KEY,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    confirmed_at timestamp(6) without time zone,
    confirmation_token character varying,
    confirmation_sent_at timestamp(6) without time zone,
    unconfirmed_email character varying,
    role user_role DEFAULT 'individual_trader'::user_role,
    trading_style character varying,
    risk_tolerance character varying,
    preferred_timeframes character varying[] DEFAULT '{}'::character varying[],
    openai_api_key character varying,
    ai_analysis_enabled boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

-- 2. Trading Accounts table
CREATE TABLE trading_accounts (
    id bigserial PRIMARY KEY,
    user_id bigint NOT NULL,
    account_name character varying NOT NULL,
    account_type account_type DEFAULT 'individual'::account_type,
    broker character varying DEFAULT 'zerodha'::character varying,
    account_number character varying,
    status account_status DEFAULT 'active'::account_status,
    initial_balance numeric(15,2) DEFAULT 0,
    current_balance numeric(15,2) DEFAULT 0,
    available_margin numeric(15,2) DEFAULT 0,
    used_margin numeric(15,2) DEFAULT 0,
    unrealized_pnl numeric(12,2) DEFAULT 0,
    realized_pnl numeric(12,2) DEFAULT 0,
    total_trades_count integer DEFAULT 0,
    winning_trades_count integer DEFAULT 0,
    losing_trades_count integer DEFAULT 0,
    largest_win numeric(12,2) DEFAULT 0,
    largest_loss numeric(12,2) DEFAULT 0,
    max_drawdown numeric(8,4) DEFAULT 0,
    sharpe_ratio numeric(6,4),
    zerodha_user_id character varying,
    zerodha_api_key character varying,
    zerodha_access_token character varying,
    encrypted_zerodha_api_secret character varying,
    last_synced_at timestamp(6) without time zone,
    is_primary boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 3. Securities table (global market data)
CREATE TABLE securities (
    id bigserial PRIMARY KEY,
    symbol character varying NOT NULL,
    company_name character varying NOT NULL,
    exchange character varying NOT NULL,
    security_type character varying DEFAULT 'stock'::character varying,
    nse_symbol character varying,
    bse_symbol character varying,
    isin character varying,
    sector character varying,
    industry character varying,
    last_price numeric(10,2),
    day_change numeric(8,2),
    day_change_percent numeric(6,2),
    volume bigint,
    avg_volume bigint,
    market_cap bigint,
    week_52_high numeric(10,2),
    week_52_low numeric(10,2),
    pe_ratio numeric(8,2),
    pb_ratio numeric(8,2),
    dividend_yield numeric(6,4),
    beta numeric(6,4),
    active boolean DEFAULT true,
    last_updated timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

-- 4. User Stock Analyses table
CREATE TABLE user_stock_analyses (
    id bigserial PRIMARY KEY,
    user_id bigint NOT NULL,
    security_id bigint NOT NULL,
    user_stage integer,
    user_rs_rank numeric(4,1),
    user_notes text,
    analysis_strategy character varying,
    setup_quality_rating integer,
    conviction_level conviction_level DEFAULT 'medium'::conviction_level,
    target_entry_price numeric(10,2),
    target_exit_price numeric(10,2),
    stop_loss_price numeric(10,2),
    last_updated_by_user timestamp(6) without time zone,
    analysis_version integer DEFAULT 1,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (security_id) REFERENCES securities(id)
);

-- 5. Trades table
CREATE TABLE trades (
    id bigserial PRIMARY KEY,
    user_id bigint NOT NULL,
    trading_account_id bigint NOT NULL,
    security_id bigint NOT NULL,
    trade_type trade_type DEFAULT 'buy'::trade_type,
    quantity integer NOT NULL,
    entry_price numeric(10,2) NOT NULL,
    exit_price numeric(10,2),
    entry_date timestamp(6) without time zone NOT NULL,
    exit_date timestamp(6) without time zone,
    gross_pnl numeric(12,2),
    brokerage numeric(8,2) DEFAULT 0,
    taxes numeric(8,2) DEFAULT 0,
    net_pnl numeric(12,2),
    strategy character varying,
    timeframe trade_timeframe DEFAULT 'swing'::trade_timeframe,
    status trade_status DEFAULT 'open'::trade_status,
    planned_stop_loss numeric(10,2),
    planned_target numeric(10,2),
    risk_amount numeric(10,2),
    risk_reward_ratio numeric(6,2),
    entry_stage integer,
    entry_rs_rank numeric(4,1),
    setup_quality integer DEFAULT 3,
    zerodha_order_id character varying,
    zerodha_trade_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (trading_account_id) REFERENCES trading_accounts(id),
    FOREIGN KEY (security_id) REFERENCES securities(id)
);

-- 6. Account Snapshots table
CREATE TABLE account_snapshots (
    id bigserial PRIMARY KEY,
    trading_account_id bigint NOT NULL,
    date date NOT NULL,
    total_value numeric(15,2) NOT NULL,
    cash_balance numeric(15,2) DEFAULT 0,
    invested_amount numeric(15,2) DEFAULT 0,
    unrealized_pnl numeric(15,2) DEFAULT 0,
    realized_pnl numeric(15,2) DEFAULT 0,
    day_pnl numeric(12,2) DEFAULT 0,
    day_pnl_percent numeric(8,4) DEFAULT 0,
    percent_deployed numeric(5,2) DEFAULT 0,
    number_of_positions integer DEFAULT 0,
    portfolio_beta numeric(6,4),
    max_drawdown numeric(8,4),
    sharpe_ratio numeric(6,4),
    synced_at timestamp(6) without time zone,
    sync_source character varying DEFAULT 'zerodha'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    FOREIGN KEY (trading_account_id) REFERENCES trading_accounts(id)
);

-- Create all indexes
CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);
CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token) WHERE (reset_password_token IS NOT NULL);
CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token) WHERE (confirmation_token IS NOT NULL);
CREATE INDEX index_users_on_role ON users USING btree (role);

CREATE INDEX index_trading_accounts_on_user_id ON trading_accounts USING btree (user_id);
CREATE INDEX index_trading_accounts_on_account_type ON trading_accounts USING btree (account_type);
CREATE INDEX index_trading_accounts_on_status ON trading_accounts USING btree (status);
CREATE INDEX index_trading_accounts_on_broker ON trading_accounts USING btree (broker);
CREATE INDEX index_trading_accounts_on_last_synced_at ON trading_accounts USING btree (last_synced_at);
CREATE UNIQUE INDEX index_trading_accounts_on_zerodha_user_id ON trading_accounts USING btree (zerodha_user_id) WHERE (zerodha_user_id IS NOT NULL);

CREATE INDEX index_securities_on_symbol ON securities USING btree (symbol);
CREATE INDEX index_securities_on_exchange ON securities USING btree (exchange);
CREATE INDEX index_securities_on_security_type ON securities USING btree (security_type);
CREATE INDEX index_securities_on_sector ON securities USING btree (sector);
CREATE INDEX index_securities_on_last_updated ON securities USING btree (last_updated);
CREATE UNIQUE INDEX index_securities_on_symbol_and_exchange ON securities USING btree (symbol, exchange);
CREATE INDEX index_securities_on_nse_symbol ON securities USING btree (nse_symbol) WHERE (nse_symbol IS NOT NULL);

CREATE UNIQUE INDEX index_user_stock_analyses_on_user_and_security ON user_stock_analyses USING btree (user_id, security_id);
CREATE INDEX index_user_stock_analyses_on_user_id ON user_stock_analyses USING btree (user_id);
CREATE INDEX index_user_stock_analyses_on_security_id ON user_stock_analyses USING btree (security_id);
CREATE INDEX index_user_stock_analyses_on_user_stage ON user_stock_analyses USING btree (user_stage);
CREATE INDEX index_user_stock_analyses_on_user_rs_rank ON user_stock_analyses USING btree (user_rs_rank);
CREATE INDEX index_user_stock_analyses_on_analysis_strategy ON user_stock_analyses USING btree (analysis_strategy);
CREATE INDEX index_user_stock_analyses_on_last_updated_by_user ON user_stock_analyses USING btree (last_updated_by_user);

CREATE INDEX index_trades_on_user_id ON trades USING btree (user_id);
CREATE INDEX index_trades_on_trading_account_id ON trades USING btree (trading_account_id);
CREATE INDEX index_trades_on_security_id ON trades USING btree (security_id);
CREATE INDEX index_trades_on_trade_type ON trades USING btree (trade_type);
CREATE INDEX index_trades_on_status ON trades USING btree (status);
CREATE INDEX index_trades_on_strategy ON trades USING btree (strategy);
CREATE INDEX index_trades_on_entry_date ON trades USING btree (entry_date);
CREATE INDEX index_trades_on_exit_date ON trades USING btree (exit_date);
CREATE INDEX index_trades_on_user_id_and_entry_date ON trades USING btree (user_id, entry_date);
CREATE INDEX index_trades_on_user_id_and_status ON trades USING btree (user_id, status);
CREATE UNIQUE INDEX index_trades_on_zerodha_trade_id ON trades USING btree (zerodha_trade_id) WHERE (zerodha_trade_id IS NOT NULL);

CREATE INDEX index_account_snapshots_on_trading_account_id ON account_snapshots USING btree (trading_account_id);
CREATE INDEX index_account_snapshots_on_date ON account_snapshots USING btree (date);
CREATE UNIQUE INDEX index_account_snapshots_on_trading_account_id_and_date ON account_snapshots USING btree (trading_account_id, date);
CREATE INDEX index_account_snapshots_on_synced_at ON account_snapshots USING btree (synced_at);
CREATE INDEX index_account_snapshots_on_date_desc ON account_snapshots USING btree (date DESC);

-- Insert schema migration records
INSERT INTO schema_migrations (version) VALUES
('001'),
('002'),
('003'),
('004'),
('005'),
('006');

-- Insert ar_internal_metadata
INSERT INTO ar_internal_metadata (key, value, created_at, updated_at) VALUES
('environment', 'production', NOW(), NOW());