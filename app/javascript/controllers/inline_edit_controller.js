import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["range", "progressValue", "status"]

  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  updateProgress() {
    this.progressValueTarget.textContent = `${this.rangeTarget.value}%`
  }

  save() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 400)
  }

  onSubmitEnd(event) {
    if (event.detail.success) {
      this.statusTarget.textContent = "Saved"
      this.statusTarget.classList.add("inline-save-success")
      clearTimeout(this.savedTimeout)
      this.savedTimeout = setTimeout(() => {
        this.statusTarget.textContent = ""
        this.statusTarget.classList.remove("inline-save-success")
      }, 2000)
    }
  }
}
