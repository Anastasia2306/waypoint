class AddMilestoneToProgressNotes < ActiveRecord::Migration[8.1]
  def change
    add_reference :progress_notes, :milestone, foreign_key: true, null: true
  end
end
