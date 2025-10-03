import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  static values = { open: Boolean }

  connect() {
    // Close sidebar when pressing Escape key
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  toggle() {
    this.openValue = !this.openValue
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    if (this.openValue) {
      // Open sidebar
      this.sidebarTarget.classList.remove("-translate-x-full")
      this.overlayTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden", "lg:overflow-auto")
    } else {
      // Close sidebar
      this.sidebarTarget.classList.add("-translate-x-full")
      this.overlayTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden", "lg:overflow-auto")
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.openValue) {
      this.close()
    }
  }
}
