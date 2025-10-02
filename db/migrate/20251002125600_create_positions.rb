class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trading_account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :average_price, precision: 10, scale: 2, null: false
      t.string :position_type, null: false, default: 'long'
      t.decimal :unrealized_pnl, precision: 12, scale: 2, default: 0.0
      t.datetime :last_updated
      t.datetime :closed_at

      t.timestamps
    end
    
    add_index :positions, [:user_id, :security_id, :trading_account_id], unique: true
    add_index :positions, [:user_id, :position_type]
    add_index :positions, [:closed_at]
  end
end
