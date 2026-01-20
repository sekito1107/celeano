import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]
  static values = {
    isOpponent: Boolean
  }

  cardTargetConnected(element) {
    if (element.hasAttribute("data-new-draw")) {
      this.animateDraw(element)
      // Remove attribute so it doesn't animate again if disconnected/reconnected rapidly
      element.removeAttribute("data-new-draw")
      element.classList.remove("animate-draw") // Remove CSS marker if present
    }
  }

  animateDraw(cardElement) {
    // Find the deck element
    // Player deck: inside .play-mat (but not .play-mat-opponent) -> .field-deck-area
    // Opponent deck: inside .play-mat-opponent -> .field-deck-area
    
    let deckSelector = ".play-mat:not(.play-mat-opponent) .field-deck-area"
    if (this.isOpponentValue) {
      deckSelector = ".play-mat-opponent .field-deck-area"
    }
    
    const deck = document.querySelector(deckSelector)
    if (!deck) {
        console.warn("Deck element not found for animation selector:", deckSelector)
        return
    }

    const deckRect = deck.getBoundingClientRect()
    const cardRect = cardElement.getBoundingClientRect()

    // Calculate center-to-center delta
    const deckCenterX = deckRect.left + deckRect.width / 2
    const deckCenterY = deckRect.top + deckRect.height / 2
    
    const cardCenterX = cardRect.left + cardRect.width / 2
    const cardCenterY = cardRect.top + cardRect.height / 2

    const deltaX = deckCenterX - cardCenterX
    const deltaY = deckCenterY - cardCenterY

    // Animate using Web Animations API
    // Ensure z-index is high during animation so it flies over other elements
    const keyframes = [
      { transform: `translate(${deltaX}px, ${deltaY}px) scale(0.2) rotate(180deg)`, opacity: 0, zIndex: 100 },
      { transform: `translate(${deltaX * 0.1}px, ${deltaY * 0.1}px) scale(1.1) rotate(5deg)`, opacity: 1, zIndex: 100, offset: 0.7 },
      { transform: `translate(0, 0) scale(1) rotate(0deg)`, opacity: 1, zIndex: "auto" }
    ]

    const animation = cardElement.animate(keyframes, {
      duration: 1200, // Slower duration as requested
      easing: "cubic-bezier(0.2, 0.8, 0.2, 1)",
      fill: "forwards"
    })
    
    // Explicitly set z-index on element style during animation if keyframes don't handle it well in all browsers
    cardElement.style.zIndex = "100"
    animation.onfinish = () => {
        cardElement.style.zIndex = ""
    }
  }
}
