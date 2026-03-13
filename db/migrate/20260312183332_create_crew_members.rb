class CreateCrewMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :crew_members do |t|
      t.string :name
      t.string :role
      t.string :email
      t.string :phone
      t.references :project, null: true, foreign_key: true

      t.timestamps
    end
  end
end
