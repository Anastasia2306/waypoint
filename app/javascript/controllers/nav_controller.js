import { Controller } from "@hotwired/stimulus"

// Подсвечивает пункт меню, раздел которого сейчас на экране (работает на главной)
export default class extends Controller {
  static targets = ["link"]

  connect() {
    const sections = this.linkTargets
      .filter((link) => link.dataset.section)
      .map((link) => document.getElementById(link.dataset.section))
      .filter(Boolean)

    if (sections.length === 0) return

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) this.activate(entry.target.id)
        })
      },
      { rootMargin: "-40% 0px -55% 0px" }
    )

    sections.forEach((section) => this.observer.observe(section))
  }

  activate(id) {
    this.linkTargets.forEach((link) => {
      link.classList.toggle("is-active", link.dataset.section === id)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
