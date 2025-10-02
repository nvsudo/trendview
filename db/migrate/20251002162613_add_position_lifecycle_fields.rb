class AddPositionLifecycleFields < ActiveRecord::Migration[8.0]
  def up
    # Add lifecycle tracking fields
    add_column :positions, :generation, :integer, default: 1, null: false
    add_column :positions, :status, :string, default: "open", null: false
    add_column :positions, :opened_at, :datetime

    # Backfill existing positions with opened_at
    execute <<-SQL
      UPDATE positions
      SET opened_at = created_at
      WHERE opened_at IS NULL
    SQL

    change_column_null :positions, :opened_at, false

    # Remove old uniqueness constraint (3 fields)
    remove_index :positions,
      name: "idx_on_user_id_security_id_trading_account_id_5d847c819e" if index_exists?(:positions, [ :user_id, :security_id, :trading_account_id ], name: "idx_on_user_id_security_id_trading_account_id_5d847c819e")

    # Add new composite unique index with generation (4 fields)
    add_index :positions,
      [ :user_id, :trading_account_id, :security_id, :generation ],
      unique: true,
      name: "idx_position_unique_identity"

    # Add partial unique index: only ONE open position per security per account
    # This prevents creating duplicate active positions
    add_index :positions,
      [ :user_id, :trading_account_id, :security_id, :status ],
      unique: true,
      where: "status = 'open'",
      name: "idx_one_open_position_per_security"

    # Add indexes for efficient querying
    add_index :positions, :status
    add_index :positions, [ :user_id, :status ]
    add_index :positions, :generation
  end

  def down
    # Remove new indexes
    remove_index :positions, name: "idx_position_unique_identity" if index_exists?(:positions, [ :user_id, :trading_account_id, :security_id, :generation ], name: "idx_position_unique_identity")
    remove_index :positions, name: "idx_one_open_position_per_security" if index_exists?(:positions, [ :user_id, :trading_account_id, :security_id, :status ], name: "idx_one_open_position_per_security")
    remove_index :positions, :status if index_exists?(:positions, :status)
    remove_index :positions, [ :user_id, :status ] if index_exists?(:positions, [ :user_id, :status ])
    remove_index :positions, :generation if index_exists?(:positions, :generation)

    # Remove new columns
    remove_column :positions, :generation
    remove_column :positions, :status
    remove_column :positions, :opened_at

    # Restore original unique index
    add_index :positions,
      [ :user_id, :security_id, :trading_account_id ],
      unique: true,
      name: "idx_on_user_id_security_id_trading_account_id_5d847c819e"
  end
end
