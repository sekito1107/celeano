import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

// Connects to data-controller="deck-selection"
export default class extends Controller {
  static targets = ["input", "status"]
  static values = {
    url: String
  }

  async select(event) {
    const selectedDeck = event.target.value
    
    // Optimistic UI update (if needed)
    // this.updateStatus(selectedDeck)

    try {
      const response = await patch(this.urlValue, {
        body: JSON.stringify({
          user: {
            selected_deck: selectedDeck
          }
        })
      })

      if (response.ok) {
        console.log("Deck updated:", selectedDeck)
        this.element.dataset.status = "saved"
        setTimeout(() => this.element.dataset.status = "", 2000)
      } else {
        console.error("Failed to update deck")
        // Revert selection or show error
        alert("デッキの変更に失敗しました。")
      }
    } catch (error) {
      console.error(error)
      alert("通信エラーが発生しました。")
    }
  }
}
