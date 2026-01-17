import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    if (event) event.stopPropagation() // Prevent bubbling
    this.modalTarget.classList.remove("hidden")
  }

  close(event) {
    // Check if click is on the backdrop (the modal target itself)
    if (event.target === this.modalTarget) {
      this.modalTarget.classList.add("hidden")
    }
  }
  
  closeButton(event) {
    event.stopPropagation()
    this.modalTarget.classList.add("hidden")
  }
}
