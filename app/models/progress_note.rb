class ProgressNote < ApplicationRecord
  belongs_to :research_project
  belongs_to :author, class_name: "User", inverse_of: :progress_notes

  validates :body, presence: true, length: { maximum: 5000 }
  validate :author_takes_part_in_project

  private

  def author_takes_part_in_project
    return if research_project.nil? || author.nil?
    return if [research_project.student_id, research_project.supervisor_id].include?(author.id)

    errors.add(:author, "должен быть студентом или научником этой работы")
  end
end
