import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["board", "graveyard", "deck"]

  connect() {
    this.isAnimating = false
    this.queue = []
  }

  // BoardControllerから呼び出される
  async playLogs(event) {
    const logs = event.detail.logs
    if (!logs || logs.length === 0) return

    this.queue.push(...logs)
    
    if (this.isAnimating) return
    
    this.isAnimating = true
    await this.processQueue()
    this.isAnimating = false

    // 全てのアニメーション完了後、必要ならリロード
    // ただし、現在はTurboリロードが動いているため、整合性に注意
  }

  async processQueue() {
    while (this.queue.length > 0) {
      const log = this.queue.shift()
      await this.playLog(log)
    }
  }

  async playLog(log) {
    console.log("Playing log:", log.event_type, log.details)

    switch (log.event_type) {
      case "unit_revealed":
        await this.animateReveal(log)
        break
      case "attack":
        await this.animateAttack(log)
        break
      case "take_damage":
        await this.animateDamage(log)
        break
      case "unit_death":
        await this.animateDeath(log)
        break
      case "spell_activation":
        await this.animateSpell(log)
        break
      case "pay_cost":
        await this.animatePayCost(log)
        break
      default:
        // 未実装のイベントは0.1秒待機して飛ばす（ログが詰まらないように）
        await this.delay(100)
        break
    }
  }

  // --- Animation Implementation ---

  async animateReveal(log) {
    const cardId = log.details.card_id
    return this.applyAnimation(`#game-card-${cardId}`, "animate-reveal", 600)
  }

  async animateAttack(log) {
    const attackerId = log.details.attacker_id
    const attackerEl = document.querySelector(`#game-card-${attackerId}`)
    if (!attackerEl) return

    const isOpponent = attackerEl.closest('.play-mat-opponent') !== null
    const directionClass = isOpponent ? "animate-attack-down" : "animate-attack-up"

    const attackAnim = this.applyAnimation(attackerEl, directionClass, 400)

    // 攻撃ログのターゲットがユニットの場合、ダメージ演出を並行実行
    if (log.details.target_type === "unit" && log.details.target_card_id) {
        this.animateDamage({
            details: {
                card_id: log.details.target_card_id,
                amount: log.details.damage
            }
        })
    }

    return attackAnim
  }

  async animateDamage(log) {
    const cardId = log.details.card_id
    const amount = log.details.amount

    // カードの振動演出
    return this.applyAnimation(`#game-card-${cardId}`, "animate-damage", 500)
  }

  async animateDeath(log) {
    const cardId = log.details.card_id
    return this.applyAnimation(`#game-card-${cardId}`, "animate-death", 800)
  }

  async animateSpell(log) {
    const cardId = log.details.card_id
    return this.applyAnimation(`#game-card-${cardId}`, "animate-spell", 700)
  }

  async animatePayCost(log) {
    const userId = log.details.user_id
    const newSan = log.details.current_san
    const amount = log.details.amount

    // StatusBarに対してカウントダウン通知
    // user_id で対象の StatusBar を特定する必要がある
    // とりあえず global に dispatch して StatusBarController 側で拾わせる
    window.dispatchEvent(new CustomEvent("game--status:update-san", {
        detail: { userId, newValue: newSan }
    }))

    await this.delay(300)
  }

  // --- Utilities ---

  applyAnimation(selectorOrEl, className, duration) {
    return new Promise(resolve => {
      const el = (typeof selectorOrEl === "string") ? document.querySelector(selectorOrEl) : selectorOrEl
      if (!el) {
        resolve()
        return
      }

      el.classList.add(className)
      setTimeout(() => {
        el.classList.remove(className)
        resolve()
      }, duration)
    })
  }

  dispatchToElement(selector, eventName, options) {
    const el = document.querySelector(selector)
    if (el) {
      el.dispatchEvent(new CustomEvent(eventName, options))
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
