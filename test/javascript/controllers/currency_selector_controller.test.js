import { afterEach, describe, expect, it } from "vitest"
import CurrencySelectorController from "../../../app/javascript/controllers/currency_selector_controller.js"
import { connectStimulusController, disconnectStimulus } from "../helpers/stimulus.js"

describe("CurrencySelectorController", () => {
  let application
  let controller

  afterEach(async () => {
    localStorage.clear()
    await disconnectStimulus(application)
    application = null
    controller = null
  })

  it("loads the saved currency on connect and updates all price cards", async () => {
    localStorage.setItem("selectedCurrency", "gbp")

    ;({ application, controller } = await connectStimulusController(
      "currency-selector",
      CurrencySelectorController,
      `
        <section data-controller="currency-selector">
          <select data-currency-selector-target="select">
            <option value="usd">USD</option>
            <option value="gbp">GBP</option>
            <option value="eur">EUR</option>
          </select>
          <div data-currency-selector-target="grid">
            <div class="pricing-card" data-usd="49" data-gbp="39" data-eur="46">
              <div class="pricing-price">$49<span class="pricing-period">/mo</span></div>
            </div>
            <div class="pricing-card" data-usd="custom" data-gbp="custom" data-eur="custom">
              <div class="pricing-price">Custom</div>
            </div>
          </div>
        </section>
      `
    ))

    expect(controller.selectTarget.value).toBe("gbp")
    expect(controller.gridTarget.querySelectorAll(".pricing-price")[0].innerHTML).toBe("£39<span class=\"pricing-period\">/mo</span>")
    expect(controller.gridTarget.querySelectorAll(".pricing-price")[1].innerHTML).toBe("Custom")
  })

  it("persists the selected currency and rerenders prices on change", async () => {
    ;({ application, controller } = await connectStimulusController(
      "currency-selector",
      CurrencySelectorController,
      `
        <section data-controller="currency-selector">
          <select data-currency-selector-target="select">
            <option value="usd">USD</option>
            <option value="gbp">GBP</option>
            <option value="eur">EUR</option>
          </select>
          <div data-currency-selector-target="grid">
            <div class="pricing-card" data-usd="149" data-gbp="119" data-eur="141">
              <div class="pricing-price">$149<span class="pricing-period">/mo</span></div>
            </div>
          </div>
        </section>
      `
    ))

    controller.change({ target: { value: "eur" } })

    expect(localStorage.getItem("selectedCurrency")).toBe("eur")
    expect(controller.gridTarget.querySelector(".pricing-price").innerHTML).toBe("€141<span class=\"pricing-period\">/mo</span>")
  })
})
