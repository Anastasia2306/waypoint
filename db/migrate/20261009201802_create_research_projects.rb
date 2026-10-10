class CreateResearchProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :research_projects do |t|
      t.string :title, null: false
      t.text :description
      t.integer :kind, null: false, default: 0
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :supervisor, null: false, foreign_key: { to_table: :users }
      t.date :starts_on
      t.date :due_on

      t.timestamps
    end
  end
end
