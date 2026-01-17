import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clearDetail(event) {
    // Only clear if the click is directly on the board or non-interactive elements
    // (Propagation is stopped by card click, so this runs for "outside" clicks)
    const previewContainer = document.getElementById("card-preview-container")
    if (!previewContainer) return

    // Do not clear if clicking inside the detail panel
    if (previewContainer.contains(event.target)) return

    delete previewContainer.dataset.pinnedBy
    previewContainer.classList.remove("active")
    previewContainer.classList.remove("pinned")
    previewContainer.innerHTML = ""
  }
}
