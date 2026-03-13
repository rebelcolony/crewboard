import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { crewMemberId: Number }

  start(event) {
    event.dataTransfer.setData("text/plain", this.crewMemberIdValue)
    event.dataTransfer.effectAllowed = "move"
    this.element.classList.add("dragging")
  }

  end() {
    this.element.classList.remove("dragging")
  }
}
