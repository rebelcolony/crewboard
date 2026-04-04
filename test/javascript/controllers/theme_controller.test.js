import { afterEach, describe, expect, it } from "vitest"
import ThemeController from "../../../app/javascript/controllers/theme_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("ThemeController", () => {
  let application
  let controller

  afterEach(async () => {
    localStorage.clear()
    document.documentElement.removeAttribute("data-theme")
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("restores the saved light theme on connect", async () => {
    localStorage.setItem("theme", "light")

    ;({ application, controller } = await connectStimulusController(
      "theme",
      ThemeController,
      '<div data-controller="theme"><span data-theme-target="icon"></span></div>'
    ))

    expect(document.documentElement.getAttribute("data-theme")).toBe("light")
    expect(controller.iconTarget.textContent).toBe("☀")
  })

  it("toggles between dark and light modes and updates the saved preference", async () => {
    ;({ application, controller } = await connectStimulusController(
      "theme",
      ThemeController,
      '<div data-controller="theme"><span data-theme-target="icon"></span></div>'
    ))

    controller.toggle()

    expect(document.documentElement.getAttribute("data-theme")).toBe("light")
    expect(localStorage.getItem("theme")).toBe("light")
    expect(controller.iconTarget.textContent).toBe("☀")

    controller.toggle()

    expect(document.documentElement.hasAttribute("data-theme")).toBe(false)
    expect(localStorage.getItem("theme")).toBe("dark")
    expect(controller.iconTarget.textContent).toBe("☾")
  })
})
