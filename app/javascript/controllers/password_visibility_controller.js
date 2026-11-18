import { Controller } from "@hotwired/stimulus"

// Show/hide password toggle (design: eye icon in the password field).
export default class extends Controller {
  static targets = ["input", "button"]

  toggle() {
    const show = this.inputTarget.type === "password"
    this.inputTarget.type = show ? "text" : "password"
    this.buttonTarget.setAttribute("aria-pressed", String(show))
    this.buttonTarget.textContent = show ? "Hide" : "Show"
  }
}
