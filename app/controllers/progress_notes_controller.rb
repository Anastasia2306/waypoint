class ProgressNotesController < ApplicationController
  include ProjectAccess

  before_action :set_project

  def create
    return deny_access unless participant?(@project)

    attrs = params.expect(progress_note: [ :body, :milestone_id ])
    milestone = @project.milestones.find(attrs[:milestone_id]) if attrs[:milestone_id].present?
    note = @project.progress_notes.build(body: attrs[:body], author: Current.user, milestone: milestone)

    if note.save
      anchor = milestone ? "milestone-#{milestone.id}" : "notes"
      redirect_to research_project_path(@project, anchor: anchor), notice: "Комментарий добавлен."
    else
      redirect_to @project, alert: note.errors.full_messages.to_sentence
    end
  end
end
