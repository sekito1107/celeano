import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: String,
    detailHtml: String
  }

  showDetail(event) {
    const previewContainer = document.getElementById("card-preview-container")
    if (!previewContainer) return

    // If pinned by another card, don't show this one
    if (previewContainer.dataset.pinnedBy && previewContainer.dataset.pinnedBy !== this.idValue) {
      return
    }

    // Inject the pre-rendered detailed view HTML
    previewContainer.innerHTML = this.detailHtmlValue
    previewContainer.classList.add("active")
  }

  hideDetail(event) {
    const previewContainer = document.getElementById("card-preview-container")
    if (!previewContainer) return

    // If pinned (by anyone), don't hide
    if (previewContainer.dataset.pinnedBy) {
      return
    }

    previewContainer.classList.remove("active")
    previewContainer.innerHTML = ""
  }

  pinDetail(event) {
    event.stopPropagation()
    const previewContainer = document.getElementById("card-preview-container")
    if (!previewContainer) return

    if (previewContainer.dataset.pinnedBy === this.idValue) {
      // Toggle off if already pinned by self
      delete previewContainer.dataset.pinnedBy
      previewContainer.classList.remove("pinned")
    } else {
      // Pin this card (overwriting any other pin)
      previewContainer.dataset.pinnedBy = this.idValue
      previewContainer.classList.add("pinned")
      this.showDetail(event) // Ensure it's shown/updated
    }
  }
}
