import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button", "query"]

  connect() {
    this.status = "all"
    this.apply()
  }

  select(event) {
    this.status = event.currentTarget.dataset.status
    this.buttonTargets.forEach((b) => b.classList.toggle("is-active", b === event.currentTarget))
    this.apply()
  }

  apply() {
    const q = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""

    this.itemTargets.forEach((el) => {
      const okStatus = this.status === "all" || el.dataset.status === this.status
      const okQuery = el.dataset.name.toLowerCase().includes(q)
      el.hidden = !(okStatus && okQuery)
    })
  }
}
