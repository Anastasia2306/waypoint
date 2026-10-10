require "rails_helper"

RSpec.describe Milestone do
  describe "#overdue?" do
    context "когда срок прошёл, а веха не закрыта" do
      it "считается просроченной" do
        milestone = create_milestone(due_on: Date.current - 1)
        expect(milestone).to be_overdue
      end
    end

    context "когда срок прошёл, но веха закрыта" do
      it "не считается просроченной" do
        milestone = create_milestone(due_on: Date.current - 3, completed_on: Date.current - 2)
        expect(milestone).not_to be_overdue
      end
    end

    context "когда срок сегодня" do
      it "ещё не просрочена" do
        milestone = create_milestone(due_on: Date.current)
        expect(milestone).not_to be_overdue
      end
    end
  end

  describe "#due_soon?" do
    context "когда срок в ближайшие 7 дней" do
      it "горит" do
        milestone = create_milestone(due_on: Date.current + 3)
        expect(milestone).to be_due_soon
      end
    end

    context "когда срок далеко" do
      it "не горит" do
        milestone = create_milestone(due_on: Date.current + 10)
        expect(milestone).not_to be_due_soon
      end
    end

    context "когда срок уже прошёл" do
      it "не горит, она уже просрочена" do
        milestone = create_milestone(due_on: Date.current - 1)
        expect(milestone).not_to be_due_soon
      end
    end
  end

  describe "#complete!" do
    context "с датой сегодня" do
      it "закрывает веху" do
        milestone = create_milestone
        milestone.complete!
        expect(milestone).to be_completed
        expect(milestone.completed_on).to eq(Date.current)
      end
    end

    context "с датой в будущем" do
      it "выбрасывает ошибку валидации" do
        milestone = create_milestone
        expect { milestone.complete!(on: Date.current + 1) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "scopes" do
    context ".overdue и .due_soon" do
      it "разделяют просроченные и горящие вехи" do
        project = create_project
        late = create_milestone(project: project, due_on: Date.current - 2)
        soon = create_milestone(project: project, due_on: Date.current + 2)
        create_milestone(project: project, due_on: Date.current + 40)

        expect(Milestone.overdue).to contain_exactly(late)
        expect(Milestone.due_soon).to contain_exactly(soon)
      end
    end
  end

  describe "validations и ассоциации" do
    it "требует название и срок" do
      milestone = Milestone.new(research_project: create_project)
      expect(milestone).not_to be_valid
      expect(milestone.errors).to include(:title, :due_on)
    end

    it "принадлежит работе" do
      expect(described_class.reflect_on_association(:research_project).macro).to eq(:belongs_to)
    end
  end
end
