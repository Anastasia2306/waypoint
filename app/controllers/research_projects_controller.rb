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
      redirect_to @project, notice: "Работа создана. Теперь добавьте вехи."
    else
      load_students
      render :new, status: :unprocessable_entity
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
end
