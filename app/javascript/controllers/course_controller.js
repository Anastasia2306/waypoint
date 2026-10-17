import { Controller } from "@hotwired/stimulus"

// Список курсов зависит от уровня обучения
const MAX_COURSE = { bachelor: 4, master: 2, postgraduate: 4 }

export default class extends Controller {
  static targets = ["level", "course"]

  connect() {
    this.update()
  }

  update() {
    const max = MAX_COURSE[this.levelTarget.value] || 0
    const current = this.courseTarget.value

    this.courseTarget.innerHTML = ""
    this.courseTarget.add(new Option("Не выбран", ""))
    for (let n = 1; n <= max; n++) {
      this.courseTarget.add(new Option(String(n), String(n)))
    }

    if (current && Number(current) <= max) this.courseTarget.value = current
  }
}
