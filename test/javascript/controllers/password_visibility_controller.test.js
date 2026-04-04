import { afterEach, describe, expect, it } from "vitest"
import PasswordVisibilityController from "../../../app/javascript/controllers/password_visibility_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("PasswordVisibilityController", () => {
  let application
  let controller

  afterEach(async () => {
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("toggles the password field visibility and icon state", async () => {
    ;({ application, controller } = await connectStimulusController(
      "password-visibility",
      PasswordVisibilityController,
      `
        <div data-controller="password-visibility">
          <input type="password" data-password-visibility-target="input">
          <svg data-password-visibility-target="showIcon"></svg>
          <svg data-password-visibility-target="hideIcon" class="hidden"></svg>
        </div>
      `
    ))

    controller.toggle()

    expect(controller.inputTarget.type).toBe("text")
    expect(controller.showIconTarget.classList.contains("hidden")).toBe(false)
    expect(controller.hideIconTarget.classList.contains("hidden")).toBe(true)

    controller.toggle()

    expect(controller.inputTarget.type).toBe("password")
    expect(controller.showIconTarget.classList.contains("hidden")).toBe(true)
    expect(controller.hideIconTarget.classList.contains("hidden")).toBe(false)
  })
})
