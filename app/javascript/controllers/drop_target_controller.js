import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { projectId: String }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    this.element.classList.add("drop-hover")
  }

  dragleave() {
    this.element.classList.remove("drop-hover")
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("drop-hover")

    const crewMemberId = event.dataTransfer.getData("text/plain")
    if (!crewMemberId) return

    const projectId = this.projectIdValue || ""
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/crew_members/${crewMemberId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({ crew_member: { project_id: projectId || null } })
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }
}
