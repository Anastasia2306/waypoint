class MilestonesController < ApplicationController
  include ProjectAccess

  before_action :set_project

  # Вехи добавляет студент этой работы
  def create
    return deny_access("Вехи добавляет студент этой работы.") unless project_student?(@project)

    milestone = @project.milestones.build(milestone_params)
    if milestone.save
      redirect_to research_project_path(@project, anchor: "milestone-#{milestone.id}"), notice: "Веха добавлена."
    else
      redirect_to @project, alert: milestone.errors.full_messages.to_sentence
    end
  end

  def complete
    return deny_access unless participant?(@project)

    milestone = @project.milestones.find(params[:id])
    milestone.complete!
    redirect_to research_project_path(@project, anchor: "milestone-#{milestone.id}"), notice: "Веха закрыта."
  end

  private

  def milestone_params
    params.expect(milestone: [ :title, :kind, :due_on ])
  end
end
