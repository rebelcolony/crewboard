class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :location
      t.integer :status
      t.integer :progress
      t.date :start_date
      t.date :target_end_date

      t.timestamps
    end
  end
end
