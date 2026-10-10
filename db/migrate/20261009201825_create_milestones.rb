class CreateMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :milestones do |t|
      t.references :research_project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :kind, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.date :due_on, null: false
      t.date :completed_on

      t.timestamps
    end

    add_index :milestones, [ :research_project_id, :due_on ]
  end
end
