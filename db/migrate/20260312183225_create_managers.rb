class CreateManagers < ActiveRecord::Migration[8.1]
  def change
    create_table :managers do |t|
      t.string :email_address
      t.string :password_digest

      t.timestamps
    end
    add_index :managers, :email_address, unique: true
  end
end
