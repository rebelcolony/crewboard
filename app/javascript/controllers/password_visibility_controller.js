import { Controller } from "@hotwired/stimulus"

// Toggles password field between password and text type
// Usage:
//   <div data-controller="password-visibility">
//     <input data-password-visibility-target="input" type="password">
//     <button data-action="click->password-visibility#toggle" type="button">
//       <svg data-password-visibility-target="showIcon">...</svg>
//       <svg data-password-visibility-target="hideIcon" class="hidden">...</svg>
//     </button>
//   </div>
export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"
    this.showIconTarget.classList.toggle("hidden", !isPassword)
    this.hideIconTarget.classList.toggle("hidden", isPassword)
  }
}
