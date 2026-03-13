class AddAccountIdToModels < ActiveRecord::Migration[8.1]
  def up
    # Add nullable account_id columns first
    add_reference :managers, :account, null: true, foreign_key: true
    add_reference :projects, :account, null: true, foreign_key: true
    add_reference :crew_members, :account, null: true, foreign_key: true

    # Add super_admin to managers
    add_column :managers, :super_admin, :boolean, default: false, null: false

    # Create a default account and backfill existing records
    account = execute("INSERT INTO accounts (name, plan, created_at, updated_at) VALUES ('Default Account', 'free', NOW(), NOW()) RETURNING id")
    account_id = account.first["id"]

    execute("UPDATE managers SET account_id = #{account_id}")
    execute("UPDATE projects SET account_id = #{account_id}")
    execute("UPDATE crew_members SET account_id = #{account_id}")

    # Now make columns non-nullable
    change_column_null :managers, :account_id, false
    change_column_null :projects, :account_id, false
    change_column_null :crew_members, :account_id, false
  end

  def down
    remove_column :managers, :super_admin
    remove_reference :crew_members, :account, foreign_key: true
    remove_reference :projects, :account, foreign_key: true
    remove_reference :managers, :account, foreign_key: true
  end
end
