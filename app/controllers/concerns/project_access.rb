module ProjectAccess
  extend ActiveSupport::Concern

  included do
    helper_method :participant?, :project_supervisor?, :project_student?
  end

  private

  def visible_projects
    Current.user.visible_projects
  end

  def set_project
    @project = visible_projects.find(params[:research_project_id])
  end

  def participant?(project)
    [ project.student_id, project.supervisor_id ].include?(Current.user.id)
  end

  def project_supervisor?(project)
    project.supervisor_id == Current.user.id
  end

  def project_student?(project)
    project.student_id == Current.user.id
  end

  def deny_access(message = "Недостаточно прав для этого действия.")
    redirect_to root_path, alert: message
  end
end
