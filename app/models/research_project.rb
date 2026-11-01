class ResearchProject < ApplicationRecord
  STALL_AFTER_DAYS = 14

  enum :kind, {
    coursework: 0,          # курсовая, 3 курс
    master_coursework: 1,   # 1 курс магистратуры
    bachelor_thesis: 2,     # ВКР бакалавра
    master_thesis: 3,       # магистерская
    postgraduate: 4         # аспирантура
  }, validate: true

  belongs_to :student, class_name: "User", inverse_of: :research_projects
  belongs_to :supervisor, class_name: "User", inverse_of: :supervised_projects
  # Новые вехи показываются сверху
  has_many :milestones, -> { order(created_at: :desc, id: :desc) },
           dependent: :destroy, inverse_of: :research_project
  has_many :progress_notes, dependent: :destroy

  normalizes :repository_url, with: ->(url) { url.strip.presence }

  validates :title, presence: true, length: { maximum: 200 }
  validates :repository_url, length: { maximum: 300 }
  validate :student_must_be_student
  validate :supervisor_must_supervise
  validate :due_on_not_before_starts_on
  validate :repository_url_is_web_link

  after_update_commit :broadcast_repository, if: :saved_change_to_repository_url?

  # Доля закрытых вех, 0..100
  def progress_percent
    list = milestones.to_a
    return 0 if list.empty?

    (list.count(&:completed?) * 100.0 / list.size).round
  end

  # Ближайшая по сроку незакрытая веха (от порядка показа не зависит)
  def next_milestone
    milestones.to_a.reject(&:completed?).min_by(&:due_on)
  end

  # Последний день, когда в работе что-то происходило
  def last_activity_on
    [
      (created_at || Time.current).to_date,
      milestones.map(&:completed_on).compact.max,
      progress_notes.map { |note| note.created_at&.to_date }.compact.max
    ].compact.max
  end

  def inactive?(today = Date.current)
    (today - last_activity_on) >= STALL_AFTER_DAYS
  end

  # Статус для интерфейса: :idle, :done, :stalled, :burning, :ontrack
  def status
    list = milestones.to_a
    return :idle if list.empty?
    return :done if list.all?(&:completed?)
    return :stalled if list.any?(&:overdue?) || inactive?
    return :burning if list.any?(&:due_soon?)

    :ontrack
  end

  private

  def broadcast_repository
    ProjectBroadcaster.new(self).repository_changed
  end

  def student_must_be_student
    return if student.nil? || student.student?

    errors.add(:student, "должен иметь роль студента")
  end

  def supervisor_must_supervise
    return if supervisor.nil? || supervisor.supervisor? || supervisor.head?

    errors.add(:supervisor, "должен быть научником или руководителем")
  end

  def due_on_not_before_starts_on
    return if starts_on.nil? || due_on.nil? || due_on >= starts_on

    errors.add(:due_on, "не может быть раньше даты начала")
  end

  # Только веб-ссылки: так нельзя подсунуть javascript: и подобное
  def repository_url_is_web_link
    return if repository_url.blank? || repository_url.match?(%r{\Ahttps?://\S+\z}i)

    errors.add(:base, "Ссылка на репозиторий должна начинаться с http:// или https://")
  end
end
