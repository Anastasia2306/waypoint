class ProgressNote < ApplicationRecord
  belongs_to :research_project
  belongs_to :author, class_name: "User", inverse_of: :progress_notes
  belongs_to :milestone, optional: true # без вехи это комментарий к самой работе

  validates :body, presence: true, length: { maximum: 5000 }
  validate :author_takes_part_in_project
  validate :milestone_belongs_to_project

  private

  def author_takes_part_in_project
    return if research_project.nil? || author.nil?
    return if [ research_project.student_id, research_project.supervisor_id ].include?(author.id)

    errors.add(:author, "должен быть студентом или научником этой работы")
  end

  def milestone_belongs_to_project
    return if milestone.nil? || research_project.nil?
    return if milestone.research_project_id == research_project.id

    errors.add(:milestone, "должна принадлежать этой работе")
  end
end
