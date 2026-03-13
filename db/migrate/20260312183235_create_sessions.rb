class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :manager, null: false, foreign_key: true
      t.string :token
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
    add_index :sessions, :token, unique: true
  end
end
