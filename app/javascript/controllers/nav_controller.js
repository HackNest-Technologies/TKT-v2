import { Controller } from "@hotwired/stimulus"

// Mobile menu disclosure: toggles aria-expanded and closes on Escape.
export default class extends Controller {
  static targets = ["toggle", "menu"]

  connect() {
    this.onKeydown = (event) => { if (event.key === "Escape") this.close(true) }
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() { document.removeEventListener("keydown", this.onKeydown) }

  toggle() {
    const open = this.toggleTarget.getAttribute("aria-expanded") !== "true"
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.menuTarget.dataset.open = String(open)
    if (open) this.menuTarget.querySelector("a")?.focus()
  }

  close(returnFocus = false) {
    if (this.toggleTarget.getAttribute("aria-expanded") !== "true") return
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.menuTarget.dataset.open = "false"
    if (returnFocus) this.toggleTarget.focus()
  }
}
