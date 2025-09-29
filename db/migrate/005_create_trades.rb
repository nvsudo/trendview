class CreateTrades < ActiveRecord::Migration[7.2]
  def change
    # Create enum types first (with existence check)
    execute <<-SQL
      DO $$ BEGIN
        CREATE TYPE trade_type AS ENUM ('buy', 'sell');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
      DO $$ BEGIN
        CREATE TYPE trade_timeframe AS ENUM ('intraday', 'swing', 'positional', 'long_term');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
      DO $$ BEGIN
        CREATE TYPE trade_status AS ENUM ('open', 'closed', 'partial');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    SQL

    create_table :trades do |t|
      # Associations
      t.references :user, null: false, foreign_key: true
      t.references :trading_account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true

      # Trade basics
      t.enum :trade_type, enum_type: :trade_type, default: 'buy'
      t.integer :quantity, null: false
      t.decimal :entry_price, precision: 10, scale: 2, null: false
      t.decimal :exit_price, precision: 10, scale: 2
      t.datetime :entry_date, null: false
      t.datetime :exit_date

      # P&L calculation
      t.decimal :gross_pnl, precision: 12, scale: 2
      t.decimal :brokerage, precision: 8, scale: 2, default: 0
      t.decimal :taxes, precision: 8, scale: 2, default: 0
      t.decimal :net_pnl, precision: 12, scale: 2

      # Trade classification
      t.string :strategy # 'stage_2_breakout', 'sepa_setup', 'pullback', etc.
      t.enum :timeframe, enum_type: :trade_timeframe, default: 'swing'
      t.enum :status, enum_type: :trade_status, default: 'open'

      # Risk management
      t.decimal :planned_stop_loss, precision: 10, scale: 2
      t.decimal :planned_target, precision: 10, scale: 2
      t.decimal :risk_amount, precision: 10, scale: 2
      t.decimal :risk_reward_ratio, precision: 6, scale: 2

      # User analysis at trade time
      t.integer :entry_stage # Stage when entered
      t.decimal :entry_rs_rank, precision: 4, scale: 1 # RS when entered
      t.integer :setup_quality, default: 3 # 1-5 rating

      # External trade ID for sync
      t.string :zerodha_order_id
      t.string :zerodha_trade_id

      # Timestamps
      t.timestamps

    end

    # Create indexes with IF NOT EXISTS protection
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_trades_on_user_id ON trades (user_id);
      CREATE INDEX IF NOT EXISTS index_trades_on_trading_account_id ON trades (trading_account_id);
      CREATE INDEX IF NOT EXISTS index_trades_on_security_id ON trades (security_id);
      CREATE INDEX IF NOT EXISTS index_trades_on_trade_type ON trades (trade_type);
      CREATE INDEX IF NOT EXISTS index_trades_on_status ON trades (status);
      CREATE INDEX IF NOT EXISTS index_trades_on_strategy ON trades (strategy);
      CREATE INDEX IF NOT EXISTS index_trades_on_entry_date ON trades (entry_date);
      CREATE INDEX IF NOT EXISTS index_trades_on_exit_date ON trades (exit_date);
      CREATE INDEX IF NOT EXISTS index_trades_on_user_id_and_entry_date ON trades (user_id, entry_date);
      CREATE INDEX IF NOT EXISTS index_trades_on_user_id_and_status ON trades (user_id, status);
      CREATE UNIQUE INDEX IF NOT EXISTS index_trades_on_zerodha_trade_id ON trades (zerodha_trade_id) WHERE zerodha_trade_id IS NOT NULL;
    SQL
  end

  def down
    drop_table :trades
    execute "DROP TYPE IF EXISTS trade_type;"
    execute "DROP TYPE IF EXISTS trade_timeframe;"
    execute "DROP TYPE IF EXISTS trade_status;"
  end
end