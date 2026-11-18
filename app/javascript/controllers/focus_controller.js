import { Controller } from "@hotwired/stimulus"

// Moves focus to an error summary when it appears, so screen reader users hear it.
export default class extends Controller {
  connect() { this.element.focus() }
}
