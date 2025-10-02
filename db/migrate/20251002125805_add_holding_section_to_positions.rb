class AddHoldingSectionToPositions < ActiveRecord::Migration[8.0]
  def change
    add_reference :positions, :holding_section, null: true, foreign_key: true
    add_index :positions, [ :user_id, :holding_section_id ]
  end
end
