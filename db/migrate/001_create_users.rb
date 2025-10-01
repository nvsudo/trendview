class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # Authentication
      t.string :email, null: false
      t.string :password_digest, null: false

      # Profile
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone_number
      t.date :date_of_birth

      # Trading preferences
      t.string :default_currency, default: 'INR'
      t.string :timezone, default: 'Asia/Kolkata'
      t.boolean :ai_insights_enabled, default: true

      # User status
      t.enum :role, enum_type: :user_role, default: 'trader'
      t.boolean :active, default: true
      t.datetime :last_login_at
      t.datetime :onboarded_at

      # Timestamps
      t.timestamps

      # Indexes
      t.index :email, unique: true
      t.index :active
      t.index :created_at
    end
  end

  def down
    drop_table :users
  end
end
