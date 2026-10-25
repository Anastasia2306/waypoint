require "rails_helper"

RSpec.describe "Happy path: от регистрации до закрытия вех", type: :request do
  describe "регистрация студента" do
    context "когда новый пользователь регистрируется" do
      it "создаёт студента и отправляет его заполнять профиль" do
        credentials = {
          email_address: "new.student@example.com",
          password: "password123",
          password_confirmation: "password123"
        }

        expect { post registration_path, params: { user: credentials } }.to change(User, :count).by(1)

        user = User.find_by!(email_address: "new.student@example.com")
        expect(user).to be_student
        expect(response).to redirect_to(edit_profile_path)

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Мой профиль")
      end
    end
  end

  describe "заполнение профиля студентом" do
    let(:student) { create_user(role: :student) }

    context "когда данные корректны" do
      it "сохраняет профиль, и имя появляется на главной" do
        sign_in(student)

        get edit_profile_path
        expect(response.body).to include("Уровень обучения", "Направление")

        profile = {
          first_name: "Анна", last_name: "Козлова", direction: "Прикладная информатика",
          degree_level: "bachelor", course: 3, group_name: "ИУ-31"
        }
        patch profile_path, params: { user: profile }

        expect(response).to redirect_to(root_path)
        expect(student.reload.display_name).to eq("Анна Козлова")
        expect(student.study_info).to eq("Прикладная информатика · Бакалавриат, 3 курс · группа ИУ-31")

        follow_redirect!
        expect(response.body).to include("Анна Козлова")
      end
    end
  end

  describe "научный трек от создания работы до закрытия вех" do
    let(:director) { create_user(role: :head, first_name: "Иван", last_name: "Руководов") }
    let(:supervisor) { create_user(role: :supervisor, manager: director, first_name: "Мария", last_name: "Петрова") }
    let!(:student) do
      create_user(role: :student, first_name: "Анна", last_name: "Козлова", degree_level: :bachelor, course: 3)
    end

    context "когда все участники делают то, что им положено" do
      it "проходит весь путь: работа, вехи, комментарии, закрытие, обзор руководителя" do
        # Шаг 1. Научник входит и создаёт работу для студента
        sign_in(supervisor)
        expect(response).to redirect_to(root_path)

        get new_research_project_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Анна Козлова")

        project_params = {
          title: "Классификация научных текстов", kind: "bachelor_thesis", student_id: student.id,
          starts_on: Date.current, due_on: Date.current + 90
        }
        expect { post research_projects_path, params: { research_project: project_params } }
          .to change(ResearchProject, :count).by(1)

        project = ResearchProject.last
        expect(project.supervisor).to eq(supervisor)
        expect(project.student).to eq(student)
        expect(response).to redirect_to(research_project_path(project))
        expect(flash[:notice]).to include("Работа создана")
        expect(project.status).to eq(:idle)

        follow_redirect!
        expect(response.body).to include("Студент ещё не добавил вехи.")
        expect(response.body).not_to include("Добавить веху")

        # Шаг 2. Студент входит и видит свою работу
        sign_out
        expect(response).to redirect_to(new_session_path)

        sign_in(student)
        get root_path
        expect(response.body).to include("Мои работы", "Классификация научных текстов")

        # Шаг 3. Студент добавляет две вехи
        soon = { title: "Обзор литературы", kind: "stage", due_on: Date.current + 3 }
        expect { post research_project_milestones_path(project), params: { milestone: soon } }
          .to change(project.milestones, :count).by(1)

        milestone = project.milestones.find_by!(title: "Обзор литературы")
        expect(milestone.kind).to eq("stage")
        expect(response).to redirect_to(research_project_path(project, anchor: "milestone-#{milestone.id}"))
        expect(project.reload.status).to eq(:burning) # срок через 3 дня

        later = { title: "Эксперименты", kind: "stage", due_on: Date.current + 40 }
        post research_project_milestones_path(project), params: { milestone: later }
        expect(project.reload.milestones.size).to eq(2)

        # Шаг 4. Студент оставляет комментарий к вехе и к самой работе
        on_milestone = { body: "Нашла пять подходящих статей", milestone_id: milestone.id }
        expect { post research_project_progress_notes_path(project), params: { progress_note: on_milestone } }
          .to change(ProgressNote, :count).by(1)
        expect(ProgressNote.last.author).to eq(student)
        expect(ProgressNote.last.milestone).to eq(milestone)

        post research_project_progress_notes_path(project), params: { progress_note: { body: "Начала писать главу 1" } }
        expect(ProgressNote.last.milestone).to be_nil

        # Шаг 5. Студент закрывает первую веху
        patch complete_research_project_milestone_path(project, milestone)
        expect(milestone.reload).to be_completed
        expect(milestone.completed_on).to eq(Date.current)
        expect(project.reload.progress_percent).to eq(50)
        expect(project.status).to eq(:ontrack)

        # Шаг 6. Научник видит прогресс и отвечает комментарием к вехе
        sign_out
        sign_in(supervisor)

        get research_project_path(project)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Обзор литературы", "Нашла пять подходящих статей", "Начала писать главу 1")

        feedback = { body: "Добавьте обзор зарубежных источников", milestone_id: milestone.id }
        expect { post research_project_progress_notes_path(project), params: { progress_note: feedback } }
          .to change(ProgressNote, :count).by(1)
        expect(ProgressNote.last.author).to eq(supervisor)
        expect(ProgressNote.last.milestone).to eq(milestone)

        get root_path
        expect(response.body).to include("Классификация научных текстов", "1 из 2 вех")

        # Шаг 7. Руководитель направления видит работу своего научника
        sign_out
        sign_in(director)

        get root_path
        expect(response.body).to include("Классификация научных текстов")

        get research_project_path(project)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "главная страница для каждой роли" do
    let(:director) { create_user(role: :head) }
    let(:supervisor) { create_user(role: :supervisor, manager: director) }
    let(:student) { create_user(role: :student) }
    let!(:project) { create_project(student: student, supervisor: supervisor, title: "Графы знаний") }

    context "когда заходит студент" do
      it "видит свои работы, без поиска по имени и без текста для научника" do
        sign_in(student)
        get root_path

        expect(response.body).to include("Мои работы", "Графы знаний", "научник видит ваш прогресс")
        expect(response.body).not_to include("Поиск по имени")
        expect(response.body).not_to include("стоит на месте")
      end
    end

    context "когда заходит научник" do
      it "видит работы студентов, поиск и кнопку создания работы" do
        sign_in(supervisor)
        get root_path

        expect(response.body).to include("Работы студентов", "Графы знаний", "Поиск по имени", "Новая работа")
      end
    end

    context "когда заходит руководитель направления" do
      it "видит работы подчинённых научников, но не может создавать работы" do
        sign_in(director)
        get root_path

        expect(response.body).to include("Работы студентов", "Графы знаний")
        expect(response.body).not_to include("Новая работа")
      end
    end
  end
end
