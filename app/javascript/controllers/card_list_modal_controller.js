import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    if (!this.hasModalTarget) {
      console.warn("card-list-modal: modal target not found")
      return
    }

    // Store reference to the element
    this.modalElement = this.modalTarget
    this.closeButtonElement = this.modalElement.querySelector(".modal-close-btn")

    // Move modal to body to bypass parent transforms (like rotation)
    document.body.appendChild(this.modalElement)

    // Manually bind events since data-action doesn't work after moving element out of scope
    this.boundCloseOverlay = this.closeOverlay.bind(this)
    this.boundCloseButton = this.closeButtonAction.bind(this)

    this.modalElement.addEventListener("click", this.boundCloseOverlay)
    if (this.closeButtonElement) {
      this.closeButtonElement.addEventListener("click", this.boundCloseButton)
    }
  }

  disconnect() {
    if (this.modalElement) {
      this.modalElement.removeEventListener("click", this.boundCloseOverlay)
      if (this.closeButtonElement) {
        this.closeButtonElement.removeEventListener("click", this.boundCloseButton)
      }
      this.modalElement.remove()
    }
  }

  open(event) {
    if (event) event.stopPropagation()
    this.modalElement.classList.remove("hidden")
  }

  closeOverlay(event) {
    if (event.target === this.modalElement) {
      this.modalElement.classList.add("hidden")
    }
  }
  
  closeButtonAction(event) {
    event.stopPropagation()
    this.modalElement.classList.add("hidden")
  }
}
