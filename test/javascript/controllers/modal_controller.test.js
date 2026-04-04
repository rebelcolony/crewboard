import { afterEach, describe, expect, it } from "vitest"
import ModalController from "../../../app/javascript/controllers/modal_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("ModalController", () => {
  let application

  afterEach(async () => {
    await disconnectStimulus(application)
    application = null
  })

  it("clears the modal frame when closing from the background", async () => {
    document.body.innerHTML = '<turbo-frame id="modal"></turbo-frame>'
    document.querySelector("turbo-frame#modal").innerHTML = `
      <div data-controller="modal">
        <div data-modal-target="content">Modal body</div>
      </div>
    `

    application = (await connectStimulusController(
      "modal",
      ModalController,
      document.body.innerHTML
    )).application
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='modal']"),
      "modal"
    )

    controller.closeBackground({ target: controller.element })

    expect(document.querySelector("turbo-frame#modal").innerHTML).toBe("")
  })

  it("keeps the modal open when clicking inside the content", async () => {
    document.body.innerHTML = '<turbo-frame id="modal"></turbo-frame>'
    document.querySelector("turbo-frame#modal").innerHTML = `
      <div data-controller="modal">
        <div data-modal-target="content">Modal body</div>
      </div>
    `

    const result = await connectStimulusController(
      "modal",
      ModalController,
      document.body.innerHTML
    )
    application = result.application
    const { controller } = result

    controller.closeBackground({ target: controller.contentTarget })

    expect(document.querySelector("turbo-frame#modal").textContent).toContain("Modal body")
  })
})
