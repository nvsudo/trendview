class CreateAccountSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :account_snapshots do |t|
      # Association
      t.references :trading_account, null: false, foreign_key: true

      # Snapshot date
      t.date :date, null: false

      # Portfolio values
      t.decimal :total_value, precision: 15, scale: 2, null: false
      t.decimal :cash_balance, precision: 15, scale: 2, default: 0
      t.decimal :invested_amount, precision: 15, scale: 2, default: 0
      t.decimal :unrealized_pnl, precision: 15, scale: 2, default: 0
      t.decimal :realized_pnl, precision: 15, scale: 2, default: 0

      # Daily metrics
      t.decimal :day_pnl, precision: 12, scale: 2, default: 0
      t.decimal :day_pnl_percent, precision: 8, scale: 4, default: 0

      # Deployment metrics
      t.decimal :percent_deployed, precision: 5, scale: 2, default: 0
      t.integer :number_of_positions, default: 0

      # Risk metrics
      t.decimal :portfolio_beta, precision: 6, scale: 4
      t.decimal :max_drawdown, precision: 8, scale: 4
      t.decimal :sharpe_ratio, precision: 6, scale: 4

      # Sync information
      t.datetime :synced_at
      t.string :sync_source, default: 'zerodha'

      # Timestamps
      t.timestamps
    end

    # Create indexes with IF NOT EXISTS protection
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_account_snapshots_on_trading_account_id ON account_snapshots (trading_account_id);
      CREATE INDEX IF NOT EXISTS index_account_snapshots_on_date ON account_snapshots (date);
      CREATE UNIQUE INDEX IF NOT EXISTS index_account_snapshots_on_trading_account_id_and_date ON account_snapshots (trading_account_id, date);
      CREATE INDEX IF NOT EXISTS index_account_snapshots_on_synced_at ON account_snapshots (synced_at);
      CREATE INDEX IF NOT EXISTS index_account_snapshots_on_date_desc ON account_snapshots (date DESC);
    SQL
  end
end
