class CreateUserStockAnalyses < ActiveRecord::Migration[7.2]
  def change
    # Create enum type first (with existence check)
    execute <<-SQL
      DO $$ BEGIN
        CREATE TYPE conviction_level AS ENUM ('low', 'medium', 'high', 'very_high');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    SQL

    create_table :user_stock_analyses do |t|
      # User and security association
      t.references :user, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true

      # Manual user analysis (core feature)
      t.integer :user_stage # 1, 2, 3, 4 (Weinstein stages)
      t.decimal :user_rs_rank, precision: 4, scale: 1 # 1.0 to 10.0 scale
      t.text :user_notes

      # Analysis metadata
      t.string :analysis_strategy # 'weinstein', 'minervini', 'custom'
      t.integer :setup_quality_rating # 1-5 stars
      t.enum :conviction_level, enum_type: :conviction_level, default: 'medium'

      # Price levels (user defined)
      t.decimal :target_entry_price, precision: 10, scale: 2
      t.decimal :target_exit_price, precision: 10, scale: 2
      t.decimal :stop_loss_price, precision: 10, scale: 2

      # Tracking
      t.datetime :last_updated_by_user
      t.integer :analysis_version, default: 1

      # Timestamps
      t.timestamps

    end

    # Create indexes with IF NOT EXISTS protection
    execute <<-SQL
      CREATE UNIQUE INDEX IF NOT EXISTS index_user_stock_analyses_on_user_and_security ON user_stock_analyses (user_id, security_id);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_user_id ON user_stock_analyses (user_id);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_security_id ON user_stock_analyses (security_id);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_user_stage ON user_stock_analyses (user_stage);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_user_rs_rank ON user_stock_analyses (user_rs_rank);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_analysis_strategy ON user_stock_analyses (analysis_strategy);
      CREATE INDEX IF NOT EXISTS index_user_stock_analyses_on_last_updated_by_user ON user_stock_analyses (last_updated_by_user);
    SQL
  end

  def down
    drop_table :user_stock_analyses
    execute "DROP TYPE IF EXISTS conviction_level;"
  end
end