class Milestone < ApplicationRecord
  DUE_SOON_DAYS = 7

  belongs_to :research_project, inverse_of: :milestones
  has_many :progress_notes, dependent: :destroy

  enum :kind, {
    stage: 0,       # этап работы
    review: 1,      # отзыв / рецензия
    conference: 2,  # выступление
    defense: 3      # защита
  }, validate: true

  validates :title, presence: true, length: { maximum: 200 }
  validates :due_on, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :completed_on_not_in_future

  scope :pending, -> { where(completed_on: nil) }
  scope :completed, -> { where.not(completed_on: nil) }
  scope :overdue, -> { pending.where(due_on: ...Date.current) }
  scope :due_soon, ->(days = DUE_SOON_DAYS) { pending.where(due_on: Date.current..(Date.current + days)) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_completion, if: :saved_change_to_completed_on?

  def completed?
    completed_on.present?
  end

  # Срок прошёл, а веха не закрыта
  def overdue?(today = Date.current)
    !completed? && due_on.present? && due_on < today
  end

  # Срок в ближайшие N дней (включая сегодня), веха не закрыта
  def due_soon?(today = Date.current, days: DUE_SOON_DAYS)
    !completed? && due_on.present? && due_on.between?(today, today + days)
  end

  def days_left(today = Date.current)
    (due_on - today).to_i
  end

  def complete!(on: Date.current)
    update!(completed_on: on)
  end

  def reopen!
    update!(completed_on: nil)
  end

  private

  def broadcast_created
    ProjectBroadcaster.new(research_project).milestone_created(self)
  end

  def broadcast_completion
    ProjectBroadcaster.new(research_project).milestone_completed(self)
  end

  def completed_on_not_in_future
    return if completed_on.nil? || completed_on <= Date.current

    errors.add(:completed_on, "не может быть в будущем")
  end
end
