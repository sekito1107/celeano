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
    try {
      await this.processQueue()
    } finally {
      this.isAnimating = false
      // 全てのアニメーション完了を通知
      this.dispatch("finished", { bubbles: true })
    }
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
    const cardEl = document.querySelector(`#game-card-${cardId}`)
    this._ensureActive(cardEl)
    return this.applyAnimation(cardEl, "animate-reveal", 1200)
  }

  async animateAttack(log) {
    const attackerId = log.details.attacker_id
    const attackerEl = document.querySelector(`#game-card-${attackerId}`)
    if (!attackerEl) return

    this._ensureActive(attackerEl)

    const isOpponent = attackerEl.closest('.play-mat-opponent') !== null
    const directionClass = isOpponent ? "animate-attack-down" : "animate-attack-up"

    const attackAnim = this.applyAnimation(attackerEl, directionClass, 800)

    // ダメージ情報の処理
    if (log.details.target_type === "unit" && log.details.target_card_id) {
        this.delay(300).then(() => {
            this.animateDamage({
                details: {
                    card_id: log.details.target_card_id,
                    amount: log.details.damage
                }
            })
        })
    } else if (log.details.target_type === "player" && log.details.target_player_id) {
        // プレイヤーへの攻撃の場合も数値を出す
        this.delay(300).then(() => {
            const targetUserId = this._findUserIdByPlayerId(log.details.target_player_id)
            const targetEl = document.querySelector(`[data-game--countdown-user-id-value="${targetUserId}"] .hero-portrait-wrapper`)
            if (targetEl) {
                this.showDamageNumber(targetEl, log.details.damage)
            }
        })
    }

    return attackAnim
  }

  async animateDamage(log) {
    const cardId = log.details.card_id
    const amount = log.details.amount

    const cardEl = document.querySelector(`#game-card-${cardId}`)
    if (cardEl) {
        this._ensureActive(cardEl)
        this.showDamageNumber(cardEl, amount)
    }

    // カードの振動演出
    return this.applyAnimation(cardEl, "animate-damage", 1000)
  }

  async animateDeath(log) {
    const cardId = log.details.card_id
    const cardEl = document.querySelector(`#game-card-${cardId}`)
    const anim = this.applyAnimation(cardEl, "animate-death", 1500)
    
    // アニメーション完了後、リロードまで一瞬表示が戻るのを防ぐため非表示にする
    anim.then(() => {
        if (cardEl) {
            cardEl.style.opacity = "0"
            cardEl.style.pointerEvents = "none"
        }
    })

    return anim
  }

  async animateSpell(log) {
    const cardId = log.details.card_id
    const cardEl = document.querySelector(`#game-card-${cardId}`)
    this._ensureActive(cardEl)
    return this.applyAnimation(cardEl, "animate-spell", 1400)
  }

  async animatePayCost(log) {
    const userId = log.details.user_id
    const newSan = log.details.current_san
    const amount = log.details.amount

    // StatusBarに対してカウントダウン通知
    window.dispatchEvent(new CustomEvent("game--status:update-san", {
        detail: { userId, newValue: newSan }
    }))

    // SANコストの支払いでも数値を出す
    const targetEl = document.querySelector(`[data-game--countdown-user-id-value="${userId}"] .hero-portrait-wrapper`)
    if (targetEl && amount > 0) {
        this.showDamageNumber(targetEl, amount)
    }

    await this.delay(300)
  }

  // --- Utilities ---

  _ensureActive(cardEl) {
    if (!cardEl) return
    // 召喚待機状態（半透明、ラベル付き）を解除してアニメーションを正しく見せる
    cardEl.classList.remove("scheduled-summon")
  }

  showDamageNumber(el, amount) {
    if (!el || !amount) return

    const damageEl = document.createElement("div")
    damageEl.className = "damage-number"
    damageEl.textContent = `-${amount}`
    
    el.appendChild(damageEl)
    
    // アニメーション終了後に削除
    setTimeout(() => {
        damageEl.remove()
    }, 1500)
  }

  _findUserIdByPlayerId(playerId) {
    // 画面内の StatusBar から playerId を持つものを探すか、
    // Railsから渡された情報を元に解決する。
    // 今回は簡易的に DOM から userId を直接引く（PlayerId と UserId の紐付けがDOMにあると仮定）
    // 実際には DataValue で player-id も持たせるのが確実。
    // 現状の実装では StatusBar に user-id-value があるので、それを利用。
    // 対戦相手のIDは view で判別可能
    
    // TODO: StatusBarComponent に player-id も持たせるとより確実
    // 同一ユーザー ID の可能性（テスト時等）を考慮し、とりあえずマッチするものを探す
    const el = document.querySelector(`[data-game--countdown-user-id-value]`)
    return el ? el.dataset.gameCountdownUserIdValue : null
  }

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
