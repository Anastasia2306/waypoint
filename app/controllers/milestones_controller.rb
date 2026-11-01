class MilestonesController < ApplicationController
  include ProjectAccess

  before_action :set_project

  # Вехи добавляет студент этой работы
  def create
    return deny_access("Вехи добавляет студент этой работы.") unless project_student?(@project)

    @milestone = @project.milestones.build(milestone_params)

    if @milestone.save
      respond_to do |format|
        format.html do
          redirect_to research_project_path(@project, anchor: "milestone-#{@milestone.id}"), notice: "Веха добавлена."
        end
        format.turbo_stream # create.turbo_stream.erb сбрасывает форму
      end
    else
      respond_to do |format|
        format.html { redirect_to @project, alert: @milestone.errors.full_messages.to_sentence }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  def complete
    return deny_access unless participant?(@project)

    milestone = @project.milestones.find(params[:id])
    milestone.complete!

    respond_to do |format|
      format.html do
        redirect_to research_project_path(@project, anchor: "milestone-#{milestone.id}"), notice: "Веха закрыта."
      end
      # Саму веху у всех обновляет рассылка (ProjectBroadcaster)
      format.turbo_stream { head :no_content }
    end
  end

  # Turbo Frame: комментарии к вехе подгружаются, когда блок раскрывают
  def comments
    @milestone = @project.milestones.find(params[:id])
    @notes = @milestone.progress_notes.includes(:author).order(:created_at)
  end

  private

  def milestone_params
    params.expect(milestone: [ :title, :kind, :due_on ])
  end
end
