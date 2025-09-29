class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.text :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
