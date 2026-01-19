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
      if (this.queue[0].event_type === "attack") {
        // 攻撃フェーズのログをまとめて取得
        const combatLogs = []
        while (this.queue.length > 0 && this.queue[0].event_type === "attack") {
          combatLogs.push(this.queue.shift())
        }
        await this.playCombatPhase(combatLogs)
      } else {
        const log = this.queue.shift()
        await this.playLog(log)
      }
    }
  }

  async playCombatPhase(combatLogs) {
    const positions = ["left", "center", "right"]
    
    for (const pos of positions) {
      const logsInPos = combatLogs.filter(log => log.details.attacker_position === pos)
      if (logsInPos.length > 0) {
        // 同じポジションの攻撃を同時に再生
        await Promise.all(logsInPos.map(log => this.playLog(log)))
        // 各ポジションの合間に少し待機して視認性を高める
        await this.delay(300)
      }
    }

    // もしポジションが特定できない攻撃（将来用）があれば最後に流す
    const remaining = combatLogs.filter(log => !positions.includes(log.details.attacker_position))
    if (remaining.length > 0) {
      await Promise.all(remaining.map(log => this.playLog(log)))
    }
  }

  async playLog(log) {
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
    let cardEl = document.querySelector(`#game-card-${cardId}`)
    if (!cardEl) return

    // 相手のカードなどでスロット外にある場合、指定のスロットへ移動させる
    if (!cardEl.closest(".field-slot")) {
      const playerId = log.details.owner_player_id
      const position = log.details.position

      const fieldEl = document.querySelector(`[data-game--animation-player-id-value="${playerId}"]`)
      if (fieldEl) {
        const slotEl = fieldEl.querySelector(`[data-game--animation-target="slot"][data-position="${position}"]`)
        if (slotEl) {
          slotEl.innerHTML = "" // empty-slot などを削除
          slotEl.appendChild(cardEl)
        }
      }
    }

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
    if (!cardEl) return

    this._ensureActive(cardEl)
    this.showDamageNumber(cardEl, amount)

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
    // scheduled-summon状態を解除してカードをアクティブにする
    cardEl.classList.remove("scheduled-summon")
    cardEl.classList.remove("state-hidden")

    // 伏せられている可能性（相手の召喚など）があるため、表側に切り替える
    const backSide = cardEl.querySelector(".card-back-side")
    const frontSide = cardEl.querySelector(".card-front-side")
    if (backSide) backSide.classList.add("hidden")
    if (frontSide) frontSide.classList.remove("hidden")
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
    // StatusBarComponent に追加した player-id-value を使って検索
    const el = document.querySelector(`[data-game--countdown-player-id-value="${playerId}"]`)
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
