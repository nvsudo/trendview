class CreateHoldingSections < ActiveRecord::Migration[8.0]
  def change
    create_table :holding_sections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0
      t.string :color, default: '#6B7280'
      t.boolean :is_default, default: false

      t.timestamps
    end
    
    add_index :holding_sections, [:user_id, :position]
    add_index :holding_sections, [:user_id, :name], unique: true
  end
end
