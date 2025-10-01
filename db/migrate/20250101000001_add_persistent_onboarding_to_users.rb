class AddPersistentOnboardingToUsers < ActiveRecord::Migration[7.2]
  def change
    # Add progressive onboarding tracking
    add_column :users, :onboarding_step, :string, default: 'profile'
    add_column :users, :onboarding_started_at, :datetime
    add_column :users, :onboarding_completed_at, :datetime

    # Track minimum scaffolding gates
    add_column :users, :has_trading_profile, :boolean, default: false
    add_column :users, :has_trading_account, :boolean, default: false
    add_column :users, :has_initial_data, :boolean, default: false

    # Store partial progress data (so users don't re-enter info)
    add_column :users, :onboarding_data, :jsonb, default: {}

    # Track which path user chose for initial data
    add_column :users, :onboarding_data_path, :string # 'zerodha', 'manual', 'watchlist'

    # Add indexes for performance
    add_index :users, :onboarding_step
    add_index :users, :onboarding_completed_at
    add_index :users, :onboarding_data, using: :gin
  end
end
