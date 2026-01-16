import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]
  static classes = ["active"]

  connect() {
    this.currentIndex = 0
    this.showSlide(this.currentIndex)
  }

  next(event) {
    if (event) event.preventDefault()
    this.currentIndex = (this.currentIndex + 1) % this.slideTargets.length
    this.showSlide(this.currentIndex)
  }

  previous(event) {
    if (event) event.preventDefault()
    this.currentIndex = (this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length
    this.showSlide(this.currentIndex)
  }

  showSlide(index) {
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove("hidden")
        slide.classList.add("active")
        // Optional: Add specific transition classes if needed
      } else {
        slide.classList.add("hidden")
        slide.classList.remove("active")
      }
    })
  }
}
