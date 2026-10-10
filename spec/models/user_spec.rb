require "rails_helper"

RSpec.describe User do
  describe "#visible_projects" do
    let!(:head) { create_user(role: :head) }
    let!(:supervisor) { create_user(role: :supervisor, manager: head) }
    let!(:other_supervisor) { create_user(role: :supervisor) }
    let!(:student) { create_user(role: :student) }
    let!(:own_project) { create_project(student: student, supervisor: supervisor) }
    let!(:foreign_project) { create_project(supervisor: other_supervisor) }

    context "для студента" do
      it "видны только его работы" do
        expect(student.visible_projects).to contain_exactly(own_project)
      end
    end

    context "для научника" do
      it "видны работы его студентов" do
        expect(supervisor.visible_projects).to contain_exactly(own_project)
      end
    end

    context "для руководителя направления" do
      it "видны работы подчинённых научников, но не чужих" do
        expect(head.visible_projects).to contain_exactly(own_project)
      end
    end
  end

  describe "#display_name" do
    context "когда указано полное имя" do
      it "возвращает его" do
        user = create_user(full_name: "Анна Иванова")
        expect(user.display_name).to eq("Анна Иванова")
      end
    end

    context "когда имени нет" do
      it "строит имя из email" do
        user = create_user(email_address: "anna.ivanova@example.com")
        expect(user.display_name).to eq("Anna Ivanova")
      end
    end
  end

  describe "validations и ассоциации" do
    it "не позволяет назначить руководителем не head" do
      user = User.new(email_address: "a@example.com", password: "password123",
                      role: :supervisor, manager: create_user(role: :student))
      expect(user).not_to be_valid
      expect(user.errors[:manager]).to be_present
    end

    it "требует уникальный email" do
      create_user(email_address: "same@example.com")
      duplicate = User.new(email_address: "same@example.com", password: "password123")
      expect(duplicate).not_to be_valid
    end

    it "собирает уникальных студентов научника через его работы" do
      supervisor = create_user(role: :supervisor)
      student = create_user(role: :student)
      2.times { create_project(student: student, supervisor: supervisor) }

      expect(supervisor.students).to contain_exactly(student)
    end
  end
end
