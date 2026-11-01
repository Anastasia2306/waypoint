class ProgressNotesController < ApplicationController
  include ProjectAccess

  before_action :set_project

  def create
    return deny_access unless participant?(@project)

    attrs = params.expect(progress_note: [ :body, :milestone_id ])
    @milestone = @project.milestones.find(attrs[:milestone_id]) if attrs[:milestone_id].present?
    @note = @project.progress_notes.build(body: attrs[:body], author: Current.user, milestone: @milestone)

    if @note.save
      respond_to do |format|
        format.html do
          redirect_to research_project_path(@project, anchor: anchor_for(@milestone)), notice: "Комментарий добавлен."
        end
        format.turbo_stream # create.turbo_stream.erb сбрасывает форму; сам комментарий приходит рассылкой
      end
    else
      respond_to do |format|
        format.html { redirect_to @project, alert: @note.errors.full_messages.to_sentence }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  private

  def anchor_for(milestone)
    milestone ? "milestone-#{milestone.id}" : "notes"
  end
end
