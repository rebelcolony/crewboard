import { afterEach, describe, expect, it, vi } from "vitest"
import DraggableController from "../../../app/javascript/controllers/draggable_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("DraggableController", () => {
  let application
  let controller

  afterEach(async () => {
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("stores the crew member id and marks the avatar as dragging on dragstart", async () => {
    const dataTransfer = {
      effectAllowed: null,
      setData: vi.fn()
    }

    ;({ application, controller } = await connectStimulusController(
      "draggable",
      DraggableController,
      '<div data-controller="draggable" data-draggable-crew-member-id-value="42"></div>'
    ))

    controller.start({ dataTransfer })

    expect(dataTransfer.setData).toHaveBeenCalledWith("text/plain", 42)
    expect(dataTransfer.effectAllowed).toBe("move")
    expect(controller.element.classList.contains("dragging")).toBe(true)
  })

  it("removes the dragging state on dragend", async () => {
    ;({ application, controller } = await connectStimulusController(
      "draggable",
      DraggableController,
      '<div class="dragging" data-controller="draggable" data-draggable-crew-member-id-value="7"></div>'
    ))

    controller.end()

    expect(controller.element.classList.contains("dragging")).toBe(false)
  })
})
