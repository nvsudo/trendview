class CreateUserUiPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_ui_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :preference_category, null: false
      t.string :preference_key, null: false
      t.jsonb :preference_value, default: {}, null: false
      t.text :description

      t.timestamps
    end

    add_index :user_ui_preferences,
              [:user_id, :preference_category, :preference_key],
              unique: true,
              name: 'index_ui_prefs_unique'

    add_index :user_ui_preferences, :preference_value, using: :gin
  end
end
