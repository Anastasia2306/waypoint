# Демо-данные для разработки: bin/rails db:seed
# Пароль у всех демо-аккаунтов: password123 (чисто для выполнения этой контрольной точки)

def demo_user(email, full_name:, role:, manager: nil)
  User.find_or_create_by!(email_address: email) do |user|
    user.full_name = full_name
    user.role = role
    user.manager = manager
    user.password = "password123"
  end
end

head = User.head.first || demo_user("head@example.com", full_name: "Руководитель Демо", role: :head)
supervisor = demo_user("supervisor@example.com", full_name: "Мария Петрова", role: :supervisor, manager: head)
demo_user("student@example.com", full_name: "Новый Студент", role: :student)

today = Date.current

# [название, тип, срок (дней от сегодня), закрыта (дней от сегодня или nil)]
projects = [
  { email: "anna@example.com", name: "Анна Козлова", title: "Классификация научных текстов",
    kind: :bachelor_thesis, note: "Собрала датасет, начинаю эксперименты.",
    milestones: [
      [ "Обзор литературы", :stage, -40, -38 ],
      [ "Постановка эксперимента", :stage, -20, -18 ],
      [ "Глава 2", :stage, 12, nil ],
      [ "Предзащита", :defense, 45, nil ]
    ] },
  { email: "igor@example.com", name: "Игорь Морозов", title: "Анализ графов знаний",
    kind: :master_thesis, note: "Не успеваю с обзором, нужна консультация.",
    milestones: [
      [ "Обзор литературы", :stage, -9, nil ],
      [ "Эксперименты", :stage, 30, nil ],
      [ "Статья", :stage, 60, nil ]
    ] },
  { email: "maria@example.com", name: "Мария Соколова", title: "Рекомендательные системы",
    kind: :coursework, note: "Курсовая сдана, жду отзыв.",
    milestones: [
      [ "Тема и план", :stage, -30, -29 ],
      [ "Текст курсовой", :stage, -10, -9 ],
      [ "Отзыв научника", :review, -3, -2 ]
    ] },
  { email: "denis@example.com", name: "Денис Лебедев", title: "Распознавание речи",
    kind: :bachelor_thesis, note: "Готовлю доклад на конференцию.",
    milestones: [
      [ "Глава 1", :stage, -15, -14 ],
      [ "Доклад на конференции", :conference, 4, nil ],
      [ "Глава 2", :stage, 30, nil ]
    ] }
]

projects.each do |data|
  student = demo_user(data[:email], full_name: data[:name], role: :student)

  project = ResearchProject.find_or_create_by!(title: data[:title], student: student) do |record|
    record.supervisor = supervisor
    record.kind = data[:kind]
    record.starts_on = today - 60
    record.due_on = today + 90
  end
  next if project.milestones.any?

  data[:milestones].each_with_index do |(title, kind, due, done), position|
    project.milestones.create!(
      title: title, kind: kind, position: position,
      due_on: today + due, completed_on: (today + done if done)
    )
  end
  project.progress_notes.create!(author: student, body: data[:note])
end
