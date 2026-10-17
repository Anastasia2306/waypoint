require "rails_helper"

RSpec.describe ProgressNote do
  let(:student) { create_user(role: :student) }
  let(:supervisor) { create_user(role: :supervisor) }
  let(:project) { create_project(student: student, supervisor: supervisor) }

  describe "комментарий к вехе" do
    context "когда веха из этой же работы" do
      it "проходит валидацию" do
        milestone = create_milestone(project: project)
        note = project.progress_notes.build(author: supervisor, body: "Добавьте источники", milestone: milestone)

        expect(note).to be_valid
      end
    end

    context "когда веха из другой работы" do
      it "не проходит валидацию" do
        note = project.progress_notes.build(author: supervisor, body: "Текст", milestone: create_milestone)

        expect(note).not_to be_valid
        expect(note.errors[:milestone]).to be_present
      end
    end
  end

  describe "автор" do
    context "когда это посторонний пользователь" do
      it "не может писать в чужой работе" do
        note = project.progress_notes.build(author: create_user(role: :supervisor), body: "Текст")

        expect(note).not_to be_valid
      end
    end

    context "когда это научник работы" do
      it "может писать комментарий к самой работе" do
        note = project.progress_notes.build(author: supervisor, body: "Хороший план")

        expect(note).to be_valid
      end
    end
  end
end
