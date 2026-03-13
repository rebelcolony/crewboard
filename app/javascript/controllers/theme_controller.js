import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "button"]

  connect() {
    const saved = localStorage.getItem("theme")
    if (saved === "light") {
      document.documentElement.setAttribute("data-theme", "light")
    }
    this.updateIcon()
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme")
    if (current === "light") {
      document.documentElement.removeAttribute("data-theme")
      localStorage.setItem("theme", "dark")
    } else {
      document.documentElement.setAttribute("data-theme", "light")
      localStorage.setItem("theme", "light")
    }
    this.updateIcon()
  }

  updateIcon() {
    const isLight = document.documentElement.getAttribute("data-theme") === "light"
    if (this.hasIconTarget) {
      this.iconTarget.textContent = isLight ? "\u2600" : "\u263E"
    }
  }
}
