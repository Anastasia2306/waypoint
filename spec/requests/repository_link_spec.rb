require "rails_helper"

RSpec.describe "Ссылка на репозиторий", type: :request do
  let(:supervisor) { create_user(role: :supervisor) }
  let(:student) { create_user(role: :student) }
  let!(:project) { create_project(student: student, supervisor: supervisor) }
  let(:link_params) { { research_project: { repository_url: "https://github.com/anna/graphs" } } }

  context "когда студент добавляет ссылку" do
    it "сохраняет её, и она видна на странице работы" do
      sign_in(student)

      patch research_project_path(project), params: link_params

      expect(response).to redirect_to(research_project_path(project))
      expect(project.reload.repository_url).to eq("https://github.com/anna/graphs")

      get research_project_path(project)
      expect(response.body).to include("github.com/anna/graphs")
    end
  end

  context "когда научник пытается добавить ссылку" do
    it "получает отказ, ссылка не сохраняется" do
      sign_in(supervisor)

      patch research_project_path(project), params: link_params

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Ссылку на репозиторий добавляет студент этой работы.")
      expect(project.reload.repository_url).to be_nil
    end
  end

  context "когда ссылка некорректна" do
    it "не сохраняется и показывает ошибку" do
      sign_in(student)

      patch research_project_path(project), params: { research_project: { repository_url: "javascript:alert(1)" } }

      expect(project.reload.repository_url).to be_nil
      expect(flash[:alert]).to be_present
    end

    it "при отправке через Turbo возвращает форму с ошибкой" do
      sign_in(student)

      patch research_project_path(project),
            params: { research_project: { repository_url: "не ссылка" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(422)
      expect(response.body).to include("form-errors")
    end
  end
end
