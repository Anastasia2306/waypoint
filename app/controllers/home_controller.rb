class HomeController < ApplicationController
  STATUS_ORDER = [ :stalled, :burning, :ontrack, :idle, :done ].freeze
  FAR_FUTURE = Date.new(9999, 12, 31)

  def index
    projects = Current.user.visible_projects
                      .includes(:student, :supervisor, :milestones, :progress_notes)
                      .to_a

    # Сначала то, что проседает и горит
    @projects = projects.sort_by do |project|
      [ STATUS_ORDER.index(project.status), project.next_milestone&.due_on || FAR_FUTURE ]
    end

    statuses = @projects.map(&:status)
    @burning = statuses.count(:burning)
    @stalled = statuses.count(:stalled)
    closed = @projects.sum { |project| project.milestones.to_a.count(&:completed?) }

    @stats = [
      { label: "Горит", value: @burning, hint: "веха в ближайшие 7 дней", status: :burning },
      { label: "Проседает", value: @stalled, hint: "просрочка или 14+ дней без движения", status: :stalled },
      { label: "Вех закрыто", value: closed, hint: "по всем работам", status: :done },
      { label: "Работ всего", value: @projects.size, hint: "под вашим наблюдением", status: :ontrack }
    ]

    upcoming = @projects.map { |project| [ project, project.next_milestone ] }
    upcoming = upcoming.select { |_project, milestone| milestone }
    @deadlines = upcoming.sort_by { |_project, milestone| milestone.due_on }.first(5)
  end
end
