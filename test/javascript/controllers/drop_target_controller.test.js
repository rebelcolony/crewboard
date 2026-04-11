import { afterEach, describe, expect, it, vi } from "vitest"
import DropTargetController from "../../../app/javascript/controllers/drop_target_controller.js"
import { connectStimulusController, disconnectStimulus, flushPromises } from "../helpers/stimulus.js"

describe("DropTargetController", () => {
  let application
  let controller

  afterEach(async () => {
    vi.unstubAllGlobals()
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("marks the target as hovered during dragover and clears it on dragleave", async () => {
    const dataTransfer = { dropEffect: null }
    const preventDefault = vi.fn()

    ;({ application, controller } = await connectStimulusController(
      "drop-target",
      DropTargetController,
      '<div data-controller="drop-target" data-drop-target-project-id-value="12"></div>'
    ))

    controller.dragover({ preventDefault, dataTransfer })

    expect(preventDefault).toHaveBeenCalled()
    expect(dataTransfer.dropEffect).toBe("move")
    expect(controller.element.classList.contains("drop-hover")).toBe(true)

    controller.dragleave()

    expect(controller.element.classList.contains("drop-hover")).toBe(false)
  })

  it("submits a reassignment request and renders the returned turbo stream", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      text: () => Promise.resolve("<turbo-stream action='replace'></turbo-stream>")
    })
    const renderStreamMessage = vi.fn()
    const preventDefault = vi.fn()

    vi.stubGlobal("fetch", fetchMock)
    vi.stubGlobal("Turbo", { renderStreamMessage })
    document.head.innerHTML = '<meta name="csrf-token" content="csrf-123">'

    ;({ application, controller } = await connectStimulusController(
      "drop-target",
      DropTargetController,
      '<div class="drop-hover" data-controller="drop-target" data-drop-target-project-id-value="12"></div>'
    ))

    controller.drop({
      preventDefault,
      dataTransfer: { getData: () => "7" }
    })
    await flushPromises()
    await flushPromises()

    expect(preventDefault).toHaveBeenCalled()
    expect(controller.element.classList.contains("drop-hover")).toBe(false)
    expect(fetchMock).toHaveBeenCalledWith("/crew_members/7", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": "csrf-123",
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({ crew_member: { project_id: "12", status: "available" } })
    })
    expect(renderStreamMessage).toHaveBeenCalledWith("<turbo-stream action='replace'></turbo-stream>")
  })

  it("does nothing when the drop payload is blank", async () => {
    const fetchMock = vi.fn()
    vi.stubGlobal("fetch", fetchMock)

    ;({ application, controller } = await connectStimulusController(
      "drop-target",
      DropTargetController,
      '<div data-controller="drop-target" data-drop-target-project-id-value=""></div>'
    ))

    controller.drop({
      preventDefault() {},
      dataTransfer: { getData: () => "" }
    })
    await flushPromises()

    expect(fetchMock).not.toHaveBeenCalled()
  })
})
