import { afterEach, beforeEach, describe, expect, it } from "vitest"
import MobileNavController from "../../../app/javascript/controllers/mobile_nav_controller.js"
import { connectStimulusController, disconnectStimulus, flushPromises } from "../helpers/stimulus.js"

describe("MobileNavController", () => {
  let application
  let controller
  const originalInnerWidth = window.innerWidth

  function setViewport(width) {
    Object.defineProperty(window, "innerWidth", {
      configurable: true,
      writable: true,
      value: width,
    })
  }

  beforeEach(() => {
    setViewport(375)
  })

  afterEach(async () => {
    setViewport(originalInnerWidth)
    document.body.classList.remove("nav-open")
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("opens the drawer, traps focus, and restores focus on close", async () => {
    ;({ application, controller } = await connectStimulusController(
      "mobile-nav",
      MobileNavController,
      `
        <nav data-controller="mobile-nav">
          <button data-mobile-nav-target="button">Menu</button>
          <div data-mobile-nav-target="menu" hidden aria-hidden="true">
            <button data-action="click->mobile-nav#closeFromOverlay" data-mobile-nav-target="overlay" tabindex="-1">Overlay</button>
            <div data-mobile-nav-target="panel">
              <button data-action="click->mobile-nav#close" data-mobile-nav-target="closeButton focusable">Close</button>
              <a href="/dashboard" data-mobile-nav-target="focusable">Dashboard</a>
            </div>
          </div>
        </nav>
      `
    ))

    controller.buttonTarget.focus()
    controller.toggle()
    await flushPromises()

    expect(controller.menuTarget.hidden).toBe(false)
    expect(controller.menuTarget.getAttribute("aria-hidden")).toBe("false")
    expect(controller.buttonTarget.getAttribute("aria-expanded")).toBe("true")
    expect(document.body.classList.contains("nav-open")).toBe(true)
    expect(document.activeElement).toBe(controller.closeButtonTarget)

    controller.close()
    await flushPromises()

    expect(controller.menuTarget.hidden).toBe(true)
    expect(controller.buttonTarget.getAttribute("aria-expanded")).toBe("false")
    expect(document.body.classList.contains("nav-open")).toBe(false)
    expect(document.activeElement).toBe(controller.buttonTarget)
  })

  it("closes when Escape is pressed", async () => {
    ;({ application, controller } = await connectStimulusController(
      "mobile-nav",
      MobileNavController,
      `
        <nav data-controller="mobile-nav">
          <button data-mobile-nav-target="button">Menu</button>
          <div data-mobile-nav-target="menu" hidden aria-hidden="true">
            <button data-action="click->mobile-nav#closeFromOverlay" data-mobile-nav-target="overlay" tabindex="-1">Overlay</button>
            <div data-mobile-nav-target="panel">
              <button data-action="click->mobile-nav#close" data-mobile-nav-target="closeButton focusable">Close</button>
            </div>
          </div>
        </nav>
      `
    ))

    controller.toggle()
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
    await flushPromises()

    expect(controller.menuTarget.hidden).toBe(true)
    expect(document.body.classList.contains("nav-open")).toBe(false)
  })

  it("shows the menu on desktop without opening the mobile drawer", async () => {
    setViewport(1280)

    ;({ application, controller } = await connectStimulusController(
      "mobile-nav",
      MobileNavController,
      `
        <nav data-controller="mobile-nav">
          <button data-mobile-nav-target="button">Menu</button>
          <div data-mobile-nav-target="menu" hidden aria-hidden="true">
            <button data-action="click->mobile-nav#closeFromOverlay" data-mobile-nav-target="overlay" tabindex="-1">Overlay</button>
            <div data-mobile-nav-target="panel">
              <a href="/dashboard" data-mobile-nav-target="focusable">Dashboard</a>
            </div>
          </div>
        </nav>
      `
    ))

    expect(controller.menuTarget.hidden).toBe(false)
    expect(controller.menuTarget.getAttribute("aria-hidden")).toBe("false")
    expect(controller.buttonTarget.getAttribute("aria-expanded")).toBe("false")
    expect(document.body.classList.contains("nav-open")).toBe(false)
  })
})
