import { Controller } from "@hotwired/stimulus"

// Плавно «набегающее» число. Без JS остаётся значение из HTML.
export default class extends Controller {
  static values = { to: Number }

  connect() {
    const end = this.toValue
    if (!end || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const duration = 900
    const start = performance.now()
    const tick = (now) => {
      const t = Math.min((now - start) / duration, 1)
      const eased = 1 - Math.pow(1 - t, 3)
      this.element.textContent = Math.round(end * eased)
      if (t < 1) this.frame = requestAnimationFrame(tick)
    }
    this.frame = requestAnimationFrame(tick)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
  }
}
