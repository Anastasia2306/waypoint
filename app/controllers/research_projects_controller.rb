class ResearchProjectsController < ApplicationController
  include ProjectAccess

  before_action :require_supervisor, only: [ :new, :create ]

  def show
    @project = visible_projects
               .includes(:student, :supervisor, :milestones, progress_notes: :author)
               .find(params[:id])
  end

  def new
    @project = ResearchProject.new(starts_on: Date.current)
    load_students
  end

  def create
    @project = ResearchProject.new(project_params)
    @project.supervisor = Current.user

    if @project.save
      redirect_to @project, notice: "Работа создана. Теперь студент может добавить вехи."
    else
      load_students
      render :new, status: :unprocessable_entity
    end
  end

  # Ссылку на репозиторий добавляет студент этой работы
  def update
    @project = visible_projects.find(params[:id])
    return deny_access("Ссылку на репозиторий добавляет студент этой работы.") unless project_student?(@project)

    if @project.update(repository_params)
      respond_to do |format|
        format.html { redirect_to @project, notice: "Ссылка на репозиторий сохранена." }
        format.turbo_stream # update.turbo_stream.erb обновляет форму
      end
    else
      respond_to do |format|
        format.html { redirect_to @project, alert: @project.errors.full_messages.to_sentence }
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  private

  def require_supervisor
    deny_access("Создавать работы могут только научники.") unless Current.user.supervisor?
  end

  def load_students
    @students = User.student.order(:full_name, :email_address)
  end

  def project_params
    params.expect(research_project: [ :title, :description, :kind, :student_id, :starts_on, :due_on ])
  end

  def repository_params
    params.expect(research_project: [ :repository_url ])
  end
end
