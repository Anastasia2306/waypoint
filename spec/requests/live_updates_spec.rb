require "rails_helper"

RSpec.describe "Живые обновления страницы работы", type: :request do
  include ActionView::RecordIdentifier

  let(:director) { create_user(role: :head) }
  let(:supervisor) { create_user(role: :supervisor, manager: director) }
  let(:student) { create_user(role: :student) }
  let!(:project) { create_project(student: student, supervisor: supervisor, title: "Графы знаний") }
  let!(:milestone) { create_milestone(project: project, title: "Обзор литературы") }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  # Запоминает, какие рассылки и в какие элементы отправила модель, и выполняет их по-настоящему
  def capture_broadcasts(*actions)
    calls = []
    actions.each do |action|
      allow(Turbo::StreamsChannel).to receive(action).and_wrap_original do |original, *args, **options|
        calls << [ action, options[:target] ]
        original.call(*args, **options)
      end
    end
    yield
    calls
  end

  describe "страница работы" do
    context "когда её открывает участник" do
      it "подписывается на поток работы и лениво подгружает комментарии вехи" do
        sign_in(student)

        get research_project_path(project)

        expect(response.body).to include("turbo-cable-stream-source")
        expect(response.body).to include(comments_research_project_milestone_path(project, milestone))
        expect(response.body).to include('loading="lazy"')
      end
    end
  end

  describe "комментарии вехи (Turbo Frame)" do
    before { project.progress_notes.create!(author: student, body: "Нашла статьи", milestone: milestone) }

    context "когда их открывает научник" do
      it "показывает комментарии и форму ответа" do
        sign_in(supervisor)

        get comments_research_project_milestone_path(project, milestone)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Нашла статьи", "Комментарий к вехе")
      end
    end

    context "когда их открывает руководитель направления" do
      it "видит комментарии, но не видит формы" do
        sign_in(director)

        get comments_research_project_milestone_path(project, milestone)

        expect(response.body).to include("Нашла статьи")
        expect(response.body).not_to include("Комментарий к вехе")
      end
    end

    context "когда их открывает чужой студент" do
      it "получает 404" do
        sign_in(create_user(role: :student))

        get comments_research_project_milestone_path(project, milestone)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "ответ на отправку формы (Turbo Stream)" do
    before { sign_in(student) }

    context "когда студент отправляет комментарий к вехе" do
      it "сбрасывает форму, не перезагружая страницу" do
        params = { progress_note: { body: "Привет", milestone_id: milestone.id } }

        post research_project_progress_notes_path(project), params: params, headers: turbo_headers

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include(%(target="#{dom_id(milestone, :comment_form)}"))
      end
    end

    context "когда комментарий пустой" do
      it "возвращает форму с ошибкой" do
        post research_project_progress_notes_path(project), params: { progress_note: { body: "" } },
                                                            headers: turbo_headers

        expect(response).to have_http_status(422)
        expect(response.body).to include("form-errors")
      end
    end

    context "когда студент добавляет веху" do
      it "добавляет её в начало списка и обновляет прогресс работы" do
        calls = capture_broadcasts(:broadcast_prepend_to, :broadcast_replace_to, :broadcast_remove_to) do
          create_milestone(project: project, title: "Новая веха")
        end

        expect(calls).to contain_exactly(
          [ :broadcast_remove_to, "milestones_empty" ],
          [ :broadcast_prepend_to, "milestones" ],
          [ :broadcast_replace_to, dom_id(project, :summary) ]
        )
      end
    end
  end

  describe "рассылка подписчикам" do
    context "когда появляется комментарий к работе" do
      it "добавляет его в начало списка комментариев работы" do
        calls = capture_broadcasts(:broadcast_prepend_to) do
          project.progress_notes.create!(author: student, body: "Начала главу 1")
        end

        expect(calls).to eq([ [ :broadcast_prepend_to, "project_notes" ] ])
      end
    end

    context "когда появляется комментарий к вехе" do
      it "добавляет его в список вехи и обновляет счётчик" do
        calls = capture_broadcasts(:broadcast_append_to, :broadcast_replace_to) do
          project.progress_notes.create!(author: supervisor, body: "Добавьте источники", milestone: milestone)
        end

        expect(calls).to contain_exactly(
          [ :broadcast_append_to, dom_id(milestone, :comments_list) ],
          [ :broadcast_replace_to, dom_id(milestone, :comments_summary) ]
        )
      end
    end

    context "когда студент добавляет веху" do
      it "добавляет её в список и обновляет прогресс работы" do
        calls = capture_broadcasts(:broadcast_prepend_to, :broadcast_replace_to, :broadcast_remove_to) do
          create_milestone(project: project, title: "Новая веха")
        end

        expect(calls).to contain_exactly(
          [ :broadcast_remove_to, "milestones_empty" ],
          [ :broadcast_prepend_to, "milestones" ],
          [ :broadcast_replace_to, dom_id(project, :summary) ]
        )
      end
    end

    context "когда веху закрывают" do
      it "обновляет строку вехи и прогресс работы у всех зрителей" do
        calls = capture_broadcasts(:broadcast_replace_to) { milestone.complete! }

        expect(calls).to contain_exactly(
          [ :broadcast_replace_to, dom_id(milestone, :row) ],
          [ :broadcast_replace_to, dom_id(project, :summary) ]
        )
      end
    end
  end
end
