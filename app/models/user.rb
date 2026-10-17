class User < ApplicationRecord
  DEGREE_LEVEL_LABELS = {
    "bachelor" => "Бакалавриат",
    "master" => "Магистратура",
    "postgraduate" => "Аспирантура"
  }.freeze

  # Сколько курсов на каждом уровне
  COURSE_LIMITS = { "bachelor" => 4, "master" => 2, "postgraduate" => 4 }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { student: 0, supervisor: 1, head: 2 }, validate: true
  enum :degree_level, { bachelor: 0, master: 1, postgraduate: 2 }, prefix: :level, validate: { allow_nil: true }

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

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, :direction, :group_name, with: ->(value) { value.strip.presence }

  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, length: { maximum: 120 }
  validates :first_name, :last_name, length: { maximum: 60 }
  validates :direction, length: { maximum: 120 }
  validates :group_name, length: { maximum: 30 }
  validates :course, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validate :course_fits_degree_level
  validate :manager_must_be_head

  # Имя для интерфейса: имя и фамилия из профиля, иначе полное имя, иначе из email
  def display_name
    profile_name = [ first_name, last_name ].compact_blank.join(" ")
    return profile_name if profile_name.present?

    full_name.presence ||
      email_address.split("@").first.tr("._-", " ").split.map(&:capitalize).join(" ")
  end

  # Полная учебная информация: «Прикладная информатика · Магистратура, 1 курс · группа ИУ-31»
  def study_info
    [ direction, level_and_course, (group_name && "группа #{group_name}") ].compact_blank.join(" · ")
  end

  # Коротко для карточек, без направления: «Магистратура, 1 курс · ИУ-31»
  def short_study_info
    [ level_and_course, group_name ].compact_blank.join(" · ")
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

  def level_and_course
    return if degree_level.nil? && course.nil?

    [ DEGREE_LEVEL_LABELS[degree_level], (course && "#{course} курс") ].compact.join(", ")
  end

  def course_fits_degree_level
    return if course.nil?

    if degree_level.nil?
      errors.add(:base, "Чтобы выбрать курс, укажите уровень обучения")
      return
    end

    max = COURSE_LIMITS.fetch(degree_level)
    return if course <= max

    errors.add(:base, "Для уровня «#{DEGREE_LEVEL_LABELS[degree_level]}» курс может быть от 1 до #{max}")
  end

  def manager_must_be_head
    return if manager.nil? || manager.head?

    errors.add(:manager, "должен быть руководителем направления")
  end
end
