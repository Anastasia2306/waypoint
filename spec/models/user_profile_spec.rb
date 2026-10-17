require "rails_helper"

RSpec.describe User do
  describe "#display_name" do
    context "когда заполнены имя и фамилия" do
      it "показывает их, а не email" do
        user = create_user(first_name: "Анна", last_name: "Козлова")

        expect(user.display_name).to eq("Анна Козлова")
      end
    end

    context "когда профиль не заполнен" do
      it "берёт полное имя" do
        expect(create_user(full_name: "Мария Петрова").display_name).to eq("Мария Петрова")
      end
    end
  end

  describe "#study_info и #short_study_info" do
    let(:student) do
      create_user(direction: "Прикладная информатика", degree_level: :master, course: 1, group_name: "ИУ-31")
    end

    context "когда указаны направление, уровень, курс и группа" do
      it "полная строка включает направление" do
        expect(student.study_info).to eq("Прикладная информатика · Магистратура, 1 курс · группа ИУ-31")
      end

      it "короткая строка для карточек обходится без направления" do
        expect(student.short_study_info).to eq("Магистратура, 1 курс · ИУ-31")
      end
    end

    context "когда ничего не указано" do
      it "возвращает пустые строки" do
        user = create_user

        expect(user.study_info).to eq("")
        expect(user.short_study_info).to eq("")
      end
    end
  end

  describe "курс и уровень обучения" do
    context "когда курс указан без уровня" do
      it "не проходит валидацию" do
        user = User.new(email_address: "a@example.com", password: "password123", course: 2)

        expect(user).not_to be_valid
        expect(user.errors[:base]).to be_present
      end
    end

    context "когда курс больше, чем бывает на уровне" do
      it "не позволяет третий курс магистратуры" do
        user = User.new(email_address: "b@example.com", password: "password123",
                        degree_level: :master, course: 3)

        expect(user).not_to be_valid
      end
    end

    context "когда курс укладывается в уровень" do
      it "разрешает третий курс аспирантуры" do
        user = User.new(email_address: "c@example.com", password: "password123",
                        degree_level: :postgraduate, course: 3)

        expect(user).to be_valid
      end
    end
  end
end
