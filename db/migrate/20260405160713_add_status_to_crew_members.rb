class AddStatusToCrewMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :crew_members, :status, :string, default: "available", null: false
  end
end
