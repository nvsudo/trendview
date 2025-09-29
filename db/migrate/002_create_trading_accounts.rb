class CreateTradingAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :trading_accounts do |t|
      # User association
      t.references :user, null: false, foreign_key: true

      # Account identification
      t.string :zerodha_user_id, null: false
      t.string :account_name, null: false
      t.enum :account_type, enum_type: :trading_account_type, default: 'personal'
      t.boolean :is_primary, default: false

      # API credentials (encrypted)
      t.text :api_credentials

      # Account status
      t.enum :status, enum_type: :account_status, default: 'active'
      t.datetime :last_synced_at
      t.text :sync_error_message

      # Account metadata
      t.string :broker_name, default: 'Zerodha'
      t.string :account_number
      t.jsonb :account_settings, default: {}

      # Timestamps
      t.timestamps

    end

    # Create indexes with IF NOT EXISTS protection
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_trading_accounts_on_user_id ON trading_accounts (user_id);
      CREATE UNIQUE INDEX IF NOT EXISTS index_trading_accounts_on_zerodha_user_id ON trading_accounts (zerodha_user_id);
      CREATE INDEX IF NOT EXISTS index_trading_accounts_on_user_id_and_is_primary ON trading_accounts (user_id, is_primary);
      CREATE INDEX IF NOT EXISTS index_trading_accounts_on_status ON trading_accounts (status);
      CREATE INDEX IF NOT EXISTS index_trading_accounts_on_account_type ON trading_accounts (account_type);
    SQL
  end

  def down
    drop_table :trading_accounts
  end
end