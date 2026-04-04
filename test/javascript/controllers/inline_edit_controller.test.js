import { afterEach, describe, expect, it, vi } from "vitest"
import InlineEditController from "../../../app/javascript/controllers/inline_edit_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("InlineEditController", () => {
  let application
  let controller

  afterEach(async () => {
    vi.useRealTimers()
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("updates the visible progress value from the range input", async () => {
    ;({ application, controller } = await connectStimulusController(
      "inline-edit",
      InlineEditController,
      `
        <form data-controller="inline-edit">
          <input data-inline-edit-target="range" value="75">
          <span data-inline-edit-target="progressValue"></span>
          <span data-inline-edit-target="status"></span>
        </form>
      `
    ))

    controller.updateProgress()

    expect(controller.progressValueTarget.textContent).toBe("75%")
  })

  it("debounces autosave requests", async () => {
    vi.useFakeTimers()

    ;({ application, controller } = await connectStimulusController(
      "inline-edit",
      InlineEditController,
      `
        <form data-controller="inline-edit">
          <input data-inline-edit-target="range" value="50">
          <span data-inline-edit-target="progressValue"></span>
          <span data-inline-edit-target="status"></span>
        </form>
      `
    ))

    controller.element.requestSubmit = vi.fn()

    controller.save()
    vi.advanceTimersByTime(200)
    controller.save()
    vi.advanceTimersByTime(399)

    expect(controller.element.requestSubmit).not.toHaveBeenCalled()

    vi.advanceTimersByTime(1)

    expect(controller.element.requestSubmit).toHaveBeenCalledTimes(1)
  })

  it("shows and clears the saved state after a successful submit", async () => {
    vi.useFakeTimers()

    ;({ application, controller } = await connectStimulusController(
      "inline-edit",
      InlineEditController,
      `
        <form data-controller="inline-edit">
          <input data-inline-edit-target="range" value="50">
          <span data-inline-edit-target="progressValue"></span>
          <span data-inline-edit-target="status"></span>
        </form>
      `
    ))

    controller.onSubmitEnd({ detail: { success: true } })

    expect(controller.statusTarget.textContent).toBe("Saved")
    expect(controller.statusTarget.classList.contains("inline-save-success")).toBe(true)

    vi.advanceTimersByTime(2000)

    expect(controller.statusTarget.textContent).toBe("")
    expect(controller.statusTarget.classList.contains("inline-save-success")).toBe(false)
  })
})
