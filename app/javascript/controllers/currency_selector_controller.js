import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "select", "grid" ]

  connect() {
    // Set initial currency from localStorage or default to USD
    const saved = localStorage.getItem("selectedCurrency") || "usd"
    this.selectTarget.value = saved
    this.updatePrices(saved)
  }

  change(event) {
    const currency = event.target.value
    localStorage.setItem("selectedCurrency", currency)
    this.updatePrices(currency)
  }

  updatePrices(currency) {
    const symbols = { usd: "$", gbp: "£", eur: "€" }
    const symbol = symbols[currency]

    // Get all pricing cards and update prices
    const cards = this.gridTarget.querySelectorAll(".pricing-card")
    
    cards.forEach(card => {
      const price = card.getAttribute(`data-${currency}`)
      const priceElement = card.querySelector(".pricing-price")

      if (!priceElement) return

      if (price === "custom") {
        priceElement.innerHTML = "Custom"
      } else if (price !== null) {
        priceElement.innerHTML = `${symbol}${price}<span class="pricing-period">/mo</span>`
      }
    })
  }
}

