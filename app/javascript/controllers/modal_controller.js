import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  closeBackground(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  close() {
    const frame = document.querySelector("turbo-frame#modal")
    if (frame) {
      frame.innerHTML = ""
    }
  }
}
