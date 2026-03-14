class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.references :account, null: false, foreign_key: true
      t.string :email
      t.string :token
      t.datetime :accepted_at
      t.references :invited_by, null: false, foreign_key: { to_table: :managers }

      t.timestamps
    end
    add_index :invites, :token, unique: true
  end
end
