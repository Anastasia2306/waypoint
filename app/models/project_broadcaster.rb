# Рассылает живые обновления страницы работы всем, кто её открыл
# (Turbo Streams поверх Action Cable).
class ProjectBroadcaster
  include ActionView::RecordIdentifier

  def initialize(project)
    @project = ResearchProject.includes(:student, :supervisor, :milestones, progress_notes: :author).find(project.id)
  end

  def note_created(note)
    safely do
      if note.milestone_id
        milestone = find_milestone(note.milestone_id)
        broadcast(:append, dom_id(milestone, :comments_list), "research_projects/note", note: note, project: @project)
        broadcast(:replace, dom_id(milestone, :comments_summary), "milestones/comments_summary",
                  milestone: milestone, count: comments_count(milestone))
      else
        broadcast(:prepend, "project_notes", "research_projects/note", note: note, project: @project)
      end
    end
  end

  def milestone_created(milestone)
    safely do
      milestone = find_milestone(milestone.id)
      Turbo::StreamsChannel.broadcast_remove_to(@project, target: "milestones_empty")
      broadcast(:append, "milestones", "milestones/milestone", milestone: milestone, project: @project)
      broadcast_summary
    end
  end

  def milestone_completed(milestone)
    safely do
      milestone = find_milestone(milestone.id)
      broadcast(:replace, dom_id(milestone, :row), "milestones/row", milestone: milestone, project: @project)
      broadcast_summary
    end
  end

  private

  def broadcast(action, target, partial, locals)
    Turbo::StreamsChannel.public_send("broadcast_#{action}_to", @project,
                                      target: target, partial: partial, locals: locals)
  end

  def broadcast_summary
    broadcast(:replace, dom_id(@project, :summary), "research_projects/summary", project: @project)
  end

  def find_milestone(id)
    @project.milestones.find { |milestone| milestone.id == id }
  end

  def comments_count(milestone)
    @project.progress_notes.to_a.count { |note| note.milestone_id == milestone.id }
  end

  # В разработке и тестах ошибки видны сразу, в продакшене рассылка не ломает сохранение записи
  def safely
    yield
  rescue StandardError => error
    raise if Rails.env.local?

    Rails.logger.error("[ProjectBroadcaster] #{error.class}: #{error.message}")
  end
end
