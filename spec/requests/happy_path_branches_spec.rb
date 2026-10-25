require "rails_helper"

RSpec.describe "Ответвления от happy path", type: :request do
  let(:director) { create_user(role: :head) }
  let(:supervisor) { create_user(role: :supervisor, manager: director) }
  let(:student) { create_user(role: :student) }
  let!(:project) { create_project(student: student, supervisor: supervisor, title: "Графы знаний") }

  describe "ветка 1: пользователь без прав пытается выполнить действие" do
    context "когда студент пытается создать работу" do
      it "не открывает форму и получает отказ" do
        sign_in(student)

        get new_research_project_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Создавать работы могут только научники.")
      end

      it "не создаёт работу через прямой запрос" do
        sign_in(student)
        params = { title: "Моя работа", kind: "coursework", student_id: student.id }

        expect { post research_projects_path, params: { research_project: params } }
          .not_to change(ResearchProject, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Создавать работы могут только научники.")
      end
    end

    context "когда научник пытается добавить веху" do
      it "не видит формы на странице работы" do
        sign_in(supervisor)

        get research_project_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Добавить веху")
      end

      it "получает отказ при прямом запросе, веха не создаётся" do
        sign_in(supervisor)
        params = { title: "Веха от научника", kind: "stage", due_on: Date.current + 5 }

        expect { post research_project_milestones_path(project), params: { milestone: params } }
          .not_to change(Milestone, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Вехи добавляет студент этой работы.")
      end
    end

    context "когда руководитель направления пытается комментировать или закрывать вехи" do
      it "может смотреть работу, но комментарий не сохраняется" do
        sign_in(director)

        get research_project_path(project)
        expect(response).to have_http_status(:ok)

        expect { post research_project_progress_notes_path(project), params: { progress_note: { body: "Привет" } } }
          .not_to change(ProgressNote, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Недостаточно прав для этого действия.")
      end

      it "не может закрыть веху" do
        milestone = create_milestone(project: project)
        sign_in(director)

        patch complete_research_project_milestone_path(project, milestone)

        expect(milestone.reload).not_to be_completed
        expect(flash[:alert]).to eq("Недостаточно прав для этого действия.")
      end
    end

    context "когда научник пытается изменить учебные данные в своём профиле" do
      it "сохраняет только имя и фамилию, остальные поля игнорируются" do
        sign_in(supervisor)

        patch profile_path, params: { user: { first_name: "Мария", direction: "Лишнее", course: 2, group_name: "Х-1" } }

        supervisor.reload
        expect(supervisor.first_name).to eq("Мария")
        expect(supervisor.direction).to be_nil
        expect(supervisor.course).to be_nil
        expect(supervisor.group_name).to be_nil
      end
    end
  end

  describe "ветка 2: чужая работа и неавторизованный доступ" do
    let(:foreign_project) { create_project(title: "Чужая работа") }

    context "когда студент открывает работу другого студента" do
      it "получает 404 и не может написать в неё комментарий" do
        sign_in(student)

        get research_project_path(foreign_project)
        expect(response).to have_http_status(:not_found)

        expect { post research_project_progress_notes_path(foreign_project), params: { progress_note: { body: "Привет" } } }
          .not_to change(ProgressNote, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "когда научник открывает работу чужого студента" do
      it "получает 404" do
        sign_in(supervisor)

        get research_project_path(foreign_project)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "когда заходит неавторизованный пользователь" do
      it "перенаправляется на вход с главной страницы" do
        get root_path

        expect(response).to redirect_to(new_session_path)
      end

      it "перенаправляется на вход со страницы работы" do
        get research_project_path(project)

        expect(response).to redirect_to(new_session_path)
      end

      it "не может создать веху без входа" do
        params = { title: "Веха", kind: "stage", due_on: Date.current + 5 }

        expect { post research_project_milestones_path(project), params: { milestone: params } }
          .not_to change(Milestone, :count)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "ветка 3: некорректные данные" do
    context "когда студент добавляет веху без названия" do
      it "веха не создаётся, пользователь видит сообщение об ошибке" do
        sign_in(student)
        params = { title: "", kind: "stage", due_on: Date.current + 5 }

        expect { post research_project_milestones_path(project), params: { milestone: params } }
          .not_to change(Milestone, :count)

        expect(response).to redirect_to(research_project_path(project))
        expect(flash[:alert]).to be_present
      end
    end

    context "когда студент отправляет пустой комментарий" do
      it "комментарий не сохраняется" do
        sign_in(student)

        expect { post research_project_progress_notes_path(project), params: { progress_note: { body: "" } } }
          .not_to change(ProgressNote, :count)

        expect(flash[:alert]).to be_present
      end
    end

    context "когда комментарий привязан к вехе из другой работы" do
      it "получает 404, комментарий не создаётся" do
        foreign_milestone = create_milestone
        sign_in(student)
        params = { body: "Не туда", milestone_id: foreign_milestone.id }

        expect { post research_project_progress_notes_path(project), params: { progress_note: params } }
          .not_to change(ProgressNote, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "когда студент выбирает курс, которого нет на его уровне" do
      it "профиль не сохраняется, форма показывает ошибку" do
        sign_in(student)

        patch profile_path, params: { user: { first_name: "Анна", degree_level: "master", course: 3 } }

        expect(response).to have_http_status(422)
        expect(response.body).to include("курс может быть от 1 до 2")
        expect(student.reload.course).to be_nil
        expect(student.first_name).to be_nil
      end
    end
  end
end
