class AddEmailVerificationToManagers < ActiveRecord::Migration[8.1]
  def change
    add_column :managers, :email_verified_at, :datetime
    add_column :managers, :email_verification_token, :string
    add_column :managers, :email_verification_token_generated_at, :datetime

    add_index :managers, :email_verification_token, unique: true, where: "email_verification_token IS NOT NULL"
  end
end
