module ApplicationHelper
  STATUS_LABELS = {
    done: "Закрыто", ontrack: "По плану", burning: "Горит",
    stalled: "Проседает", idle: "Не начато"
  }.freeze

  def status_badge(status)
    tag.span STATUS_LABELS.fetch(status), class: "badge badge--#{status}"
  end

  def display_name(user)
    user.email_address.split("@").first.tr("._-", " ").split.map(&:capitalize).join(" ")
  end

  def initials(name)
    name.split.map { |part| part[0] }.first(2).join.upcase
  end
end
