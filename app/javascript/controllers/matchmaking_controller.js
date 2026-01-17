import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { 
    userId: Number,
    waitDuration: { type: Number, default: 6000 },
    matched: Boolean,
    gameId: Number
  }
  static targets = ["searchingState", "matchedState"]

  connect() {
    this.consumer = createConsumer()
    this.channel = this.consumer.subscriptions.create(
      { channel: "MatchmakingChannel" },
      { 
        received: this.handleMessage.bind(this) 
      }
    )

    if (this.matchedValue && this.gameIdValue) {
      this.matched = true
      this.triggerEncounterAnimation(this.gameIdValue)
    } else {
      this.matched = false
    }
  }

  disconnect() {
    this.channel?.unsubscribe()
    this.consumer?.disconnect()
    if (this.redirectTimeoutId) clearTimeout(this.redirectTimeoutId)
  }

  handleMessage(data) {
    if (data.action === "matched" && !this.matched) {
      this.matched = true
      this.triggerEncounterAnimation(data.game_id)
    }
  }

  triggerEncounterAnimation(gameId) {
    // コンテナ全体に match-found クラスを追加
    this.element.classList.add("match-found")

    // ステータステキストの表示切替
    if (this.hasSearchingStateTarget) {
      this.searchingStateTarget.classList.add("hidden")
    }
    
    if (this.hasMatchedStateTarget) {
      this.matchedStateTarget.classList.remove("hidden")
    }

    this.redirectTimeoutId = setTimeout(() => {
      if (window.Turbo) {
        window.Turbo.visit(`/games/${gameId}`)
      } else {
        window.location.href = `/games/${gameId}`
      }
    }, this.waitDurationValue)
  }
}
