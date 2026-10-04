class HomeController < ApplicationController
  def index
    @stats = [
      { label: "Горит", value: 3, hint: "дедлайн в ближайшие 7 дней", status: :burning },
      { label: "Проседает", value: 2, hint: "нет движения 14+ дней", status: :stalled },
      { label: "Вех закрыто", value: 24, hint: "в этом семестре", status: :done },
      { label: "Артефакты", value: 5, hint: "отзывы и выступления", status: :ontrack }
    ]

    @students = [
      { name: "Анна К.", work: "ВКР бакалавра", done: 4, total: 6, status: :ontrack, next: "Глава 2, 12 окт" },
      { name: "Игорь М.", work: "Магистерская", done: 2, total: 8, status: :stalled, next: "Обзор литературы, просрочено" },
      { name: "Мария С.", work: "Курсовая, 3 курс", done: 5, total: 5, status: :done, next: "Отзыв готов" },
      { name: "Денис Л.", work: "ВКР бакалавра", done: 3, total: 6, status: :burning, next: "Доклад на конференции, 9 окт" }
    ]

    @burning = @students.count { |s| s[:status] == :burning }
    @stalled = @students.count { |s| s[:status] == :stalled }
  end
end
