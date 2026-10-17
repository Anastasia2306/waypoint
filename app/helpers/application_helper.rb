module ApplicationHelper
  STATUS_LABELS = {
    done: "Закрыто", ontrack: "По плану", burning: "Горит",
    stalled: "Проседает", idle: "Не начато"
  }.freeze

  PROJECT_KIND_LABELS = {
    "coursework" => "Курсовая работа",
    "master_coursework" => "Курсовая, магистратура",
    "bachelor_thesis" => "ВКР бакалавра",
    "master_thesis" => "Магистерская диссертация",
    "postgraduate" => "Аспирантура"
  }.freeze

  MILESTONE_KIND_LABELS = {
    "stage" => "Этап", "review" => "Отзыв",
    "conference" => "Выступление", "defense" => "Защита"
  }.freeze

  ROLE_LABELS = {
    "student" => "студент", "supervisor" => "научник", "head" => "руководитель направления"
  }.freeze

  MONTHS = %w[янв фев мар апр мая июн июл авг сен окт ноя дек].freeze

  def status_badge(status)
    tag.span STATUS_LABELS.fetch(status), class: "badge badge--#{status}"
  end

  def display_name(user) = user.display_name

  def initials(name)
    name.split.map { |part| part[0] }.first(2).join.upcase
  end

  def short_date(date)
    "#{date.day} #{MONTHS[date.month - 1]}"
  end

  def project_kind_label(kind)
    PROJECT_KIND_LABELS.fetch(kind.to_s, kind.to_s)
  end

  def milestone_kind_label(kind)
    MILESTONE_KIND_LABELS.fetch(kind.to_s, kind.to_s)
  end

  def role_label(user)
    ROLE_LABELS.fetch(user.role, user.role)
  end

  # Статус одной вехи для бейджа
  def milestone_status(milestone)
    return :done if milestone.completed?
    return :stalled if milestone.overdue?
    return :burning if milestone.due_soon?

    :ontrack
  end

  # [закрыто, всего]
  def milestone_counts(project)
    list = project.milestones.to_a
    [ list.count(&:completed?), list.size ]
  end

  # Какой пункт верхнего меню подсвечен на сервере.
  # На главной подсветку дальше ведёт nav_controller.js по прокрутке.
  def nav_active?(key)
    case key
    when :overview then controller_name == "home"
    when :students then controller_name == "research_projects" && action_name == "show"
    when :new_project then controller_name == "research_projects" && %w[new create].include?(action_name)
    else false
    end
  end

  def nav_link(label, path, key, section: nil)
    data = { nav_target: "link" }
    data[:section] = section if section

    link_to label, path, class: class_names("is-active": nav_active?(key)).presence, data: data
  end
end
