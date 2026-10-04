import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark"
    document.documentElement.dataset.theme = next
    try { localStorage.setItem("theme", next) } catch (e) {}
  }
}
