require "rails_helper"

RSpec.describe ResearchProject do
  describe "#progress_percent" do
    context "когда вех нет" do
      it "равен 0" do
        expect(create_project.progress_percent).to eq(0)
      end
    end

    context "когда закрыта одна веха из четырёх" do
      it "равен 25" do
        project = create_project
        first = create_milestone(project: project)
        3.times { create_milestone(project: project) }
        first.complete!

        expect(project.reload.progress_percent).to eq(25)
      end
    end

    context "когда закрыты все вехи" do
      it "равен 100" do
        project = create_project
        2.times { create_milestone(project: project).complete! }

        expect(project.reload.progress_percent).to eq(100)
      end
    end
  end

  describe "#status" do
    let(:project) { create_project }

    context "когда вех ещё нет" do
      it "не начато" do
        expect(project.status).to eq(:idle)
      end
    end

    context "когда все вехи закрыты" do
      it "закрыто" do
        create_milestone(project: project).complete!
        expect(project.reload.status).to eq(:done)
      end
    end

    context "когда есть просроченная веха" do
      it "проседает" do
        create_milestone(project: project, due_on: Date.current - 1)
        expect(project.reload.status).to eq(:stalled)
      end
    end

    context "когда ближайшая веха через несколько дней" do
      it "горит" do
        create_milestone(project: project, due_on: Date.current + 3)
        expect(project.reload.status).to eq(:burning)
      end
    end

    context "когда движения нет 14 дней и больше" do
      it "проседает, хотя сроки ещё не вышли" do
        create_milestone(project: project, due_on: Date.current + 90)

        travel_to(15.days.from_now) do
          expect(project.reload.status).to eq(:stalled)
        end
      end
    end

    context "когда всё идёт по графику" do
      it "по плану" do
        create_milestone(project: project, due_on: Date.current + 60)
        expect(project.reload.status).to eq(:ontrack)
      end
    end
  end

  describe "#next_milestone" do
    context "когда есть закрытые и открытые вехи" do
      it "возвращает ближайшую незакрытую" do
        project = create_project
        create_milestone(project: project, due_on: Date.current + 5).complete!
        nearest = create_milestone(project: project, due_on: Date.current + 10)
        create_milestone(project: project, due_on: Date.current + 20)

        expect(project.reload.next_milestone).to eq(nearest)
      end
    end
  end

  describe "validations" do
    it "не принимает в роли студента научника" do
      project = described_class.new(title: "X", kind: :coursework,
                                    student: create_user(role: :supervisor),
                                    supervisor: create_user(role: :supervisor))
      expect(project).not_to be_valid
      expect(project.errors[:student]).to be_present
    end

    it "не принимает срок раньше начала" do
      project = build_stubbed_project(starts_on: Date.current, due_on: Date.current - 1)
      expect(project).not_to be_valid
      expect(project.errors[:due_on]).to be_present
    end

    def build_stubbed_project(**attrs)
      described_class.new({ title: "X", kind: :coursework,
                            student: create_user(role: :student),
                            supervisor: create_user(role: :supervisor) }.merge(attrs))
    end
  end
end
