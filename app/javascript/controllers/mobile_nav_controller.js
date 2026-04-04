import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.open = false
    this.sync()
  }

  disconnect() {
    document.body.classList.remove("nav-open")
  }

  toggle() {
    this.open = !this.open
    this.sync()
  }

  close() {
    if (!this.open) return

    this.open = false
    this.sync()
  }

  closeOnDesktop() {
    if (window.innerWidth > 768) {
      this.close()
    }
  }

  sync() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("is-open", this.open)
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", String(this.open))
    }

    document.body.classList.toggle("nav-open", this.open && window.innerWidth <= 768)
  }
}
