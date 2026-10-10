module Builders
  def create_user(role: :student, **attrs)
    User.create!({
      email_address: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: role
    }.merge(attrs))
  end

  def create_project(student: create_user(role: :student),
                     supervisor: create_user(role: :supervisor), **attrs)
    ResearchProject.create!({
      title: "ВКР",
      kind: :bachelor_thesis,
      student: student,
      supervisor: supervisor
    }.merge(attrs))
  end

  def create_milestone(project: create_project, **attrs)
    project.milestones.create!({
      title: "Глава 1",
      due_on: Date.current + 30
    }.merge(attrs))
  end
end