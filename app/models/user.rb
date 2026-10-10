class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { student: 0, supervisor: 1, head: 2 }, validate: true

  # Руководитель направления -> его научники
  belongs_to :manager, class_name: "User", optional: true
  has_many :managed_supervisors, class_name: "User", foreign_key: :manager_id,
           inverse_of: :manager, dependent: :nullify

  # Работы, где пользователь студент / научник
  has_many :research_projects, foreign_key: :student_id,
           inverse_of: :student, dependent: :restrict_with_error
  has_many :supervised_projects, class_name: "ResearchProject", foreign_key: :supervisor_id,
           inverse_of: :supervisor, dependent: :restrict_with_error
  has_many :students, -> { distinct }, through: :supervised_projects, source: :student
  has_many :progress_notes, foreign_key: :author_id, inverse_of: :author, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, length: { maximum: 120 }
  validate :manager_must_be_head

  # Имя для интерфейса: полное имя или имя из email
  def display_name
    full_name.presence ||
      email_address.split("@").first.tr("._-", " ").split.map(&:capitalize).join(" ")
  end

  # Какие работы пользователь вправе видеть (основа для дашборда)
  def visible_projects
    case role
    when "student" then research_projects
    when "supervisor" then supervised_projects
    when "head"
      ResearchProject.where(supervisor_id: managed_supervisors.select(:id))
                     .or(ResearchProject.where(supervisor_id: id))
    end
  end

  private

  def manager_must_be_head
    return if manager.nil? || manager.head?

    errors.add(:manager, "должен быть руководителем направления")
  end
end
