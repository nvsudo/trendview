class CreateSecurities < ActiveRecord::Migration[7.2]
  def change
    # Create enum type first (with existence check)
    execute <<-SQL
      DO $$ BEGIN
        CREATE TYPE security_type AS ENUM ('stock', 'future', 'option', 'etf', 'mutual_fund', 'currency', 'commodity');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    SQL

    create_table :securities do |t|
      # Basic identification
      t.string :symbol, null: false
      t.string :nse_symbol
      t.string :bse_symbol
      t.string :company_name, null: false

      # Classification
      t.string :exchange, null: false # NSE, BSE
      t.string :segment # EQ, FUT, OPT, CDS, etc.
      t.enum :security_type, enum_type: :security_type, default: 'stock'
      t.string :sector
      t.string :industry

      # Market data (centralized for all users)
      t.decimal :last_price, precision: 10, scale: 2
      t.decimal :day_change, precision: 10, scale: 2
      t.decimal :day_change_percent, precision: 8, scale: 4
      t.decimal :week_52_high, precision: 10, scale: 2
      t.decimal :week_52_low, precision: 10, scale: 2

      # Trading information
      t.bigint :volume
      t.decimal :avg_volume, precision: 15, scale: 2
      t.decimal :market_cap, precision: 15, scale: 2
      t.integer :lot_size, default: 1

      # Data sync information
      t.string :data_provider, default: 'zerodha'
      t.datetime :last_updated
      t.boolean :active, default: true

      # Timestamps
      t.timestamps

      # Indexes for performance
      t.index :symbol
      t.index [:symbol, :exchange], unique: true
      t.index :nse_symbol
      t.index :exchange
      t.index :security_type
      t.index :sector
      t.index :active
      t.index :last_updated
    end

  end

  def down
    drop_table :securities
    execute "DROP TYPE IF EXISTS security_type;"
  end
end