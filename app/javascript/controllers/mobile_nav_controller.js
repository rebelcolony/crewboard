import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "panel", "overlay", "closeButton", "focusable"]

  connect() {
    this.open = false
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.sync()
  }

  disconnect() {
    this.teardown()
  }

  toggle() {
    this.open = !this.open
    this.sync()
  }

  close() {
    if (!this.open) return

    this.open = false
    this.sync()
  }

  closeOnDesktop() {
    this.syncOnResize()
  }

  syncOnResize() {
    if (window.innerWidth > 768) {
      this.open = false
    }

    this.sync()
  }

  closeBeforeCache() {
    this.open = false
    this.sync()
  }

  closeFromOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  handleTab(event) {
    if (!this.open || !this.hasFocusableTarget || this.focusableTargets.length === 0) return

    const focusable = this.visibleFocusableTargets
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const active = document.activeElement

    if (event.shiftKey && active === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  handleKeydown(event) {
    if (!this.open) return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key === "Tab") {
      this.handleTab(event)
    }
  }

  sync() {
    const desktop = window.innerWidth > 768
    const mobileOpen = this.open && !desktop
    const menuVisible = desktop || mobileOpen

    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("is-open", mobileOpen)
      this.menuTarget.toggleAttribute("hidden", !menuVisible)
      this.menuTarget.setAttribute("aria-hidden", String(!menuVisible))
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", String(mobileOpen))
    }

    if (this.hasPanelTarget) {
      if (mobileOpen) {
        this.panelTarget.setAttribute("tabindex", "-1")
      } else {
        this.panelTarget.removeAttribute("tabindex")
      }
    }

    document.body.classList.toggle("nav-open", mobileOpen)

    if (mobileOpen) {
      document.addEventListener("keydown", this.boundHandleKeydown)
      this.previousActiveElement = document.activeElement
      this.focusFirstTarget()
    } else {
      document.removeEventListener("keydown", this.boundHandleKeydown)
      this.restoreFocus()
    }
  }

  focusFirstTarget() {
    const [firstTarget] = this.visibleFocusableTargets
    ;(firstTarget || this.closeButtonTarget || this.panelTarget)?.focus()
  }

  restoreFocus() {
    if (this.previousActiveElement && typeof this.previousActiveElement.focus === "function") {
      this.previousActiveElement.focus()
    }
    this.previousActiveElement = null
  }

  teardown() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.body.classList.remove("nav-open")
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("is-open")
      this.menuTarget.setAttribute("aria-hidden", "true")
      this.menuTarget.setAttribute("hidden", "")
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }

  get visibleFocusableTargets() {
    return this.focusableTargets.filter((element) => {
      if (element.hasAttribute("disabled")) return false
      if (element.hidden || element.closest("[hidden]")) return false
      if (element.getAttribute("aria-hidden") === "true") return false
      const style = getComputedStyle(element)
      return style.display !== "none" && style.visibility !== "hidden"
    })
  }
}
