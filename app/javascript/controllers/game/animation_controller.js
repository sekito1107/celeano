import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["board", "graveyard", "deck"]
  static values = {
         currentPlayerId: Number
  }

  connect() {
    this.isAnimating = false
    this.queue = []
  }

  // ... (connect, etc - existing code)



  // BoardControllerから呼び出される
  async playLogs(event) {
    const logs = event.detail.logs
    if (!logs || logs.length === 0) return

    this.queue.push(...logs)
    if (this.isAnimating) return
    
    this.isAnimating = true
    try {
      while (this.queue.length > 0) {
        await this.processQueue()
      }
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
        await this.delay(500) // Phase transition delay
      } else {
        const log = this.queue.shift()
        await this.playLog(log)
        await this.delay(600) // General log delay
      }
    }
  }

  async playCombatPhase(combatLogs) {
    // 画面上の列（Column）ごとにウェーブを分ける
    const waves = [[], [], []]

    combatLogs.forEach(log => {
      const attackerId = log.details.attacker_id
      const attackerEl = document.querySelector(`#game-card-${attackerId}`)
      if (!attackerEl) return

      const waveIndex = this._calculateWaveIndex(log.details.attacker_position, attackerEl)
      if (waveIndex !== -1) {
        waves[waveIndex].push(log)
      } else {
        waves[0].push(log)
      }
    })

    for (const waveLogs of waves) {
      if (waveLogs.length > 0) {
        // 同じ列の攻撃を同時に再生
        await Promise.all(waveLogs.map(log => this.playLog(log)))
        await this.delay(800) // Slower wave transition
      }
    }
  }

  _calculateWaveIndex(position, element) {
    const isOpponent = element.closest('.play-mat-opponent') !== null
    
    // Column 0: 自分Left & 相手Right
    // Column 1: 自分Center & 相手Center
    // Column 2: 自分Right & 相手Left
    switch (position) {
      case "left":   return isOpponent ? 2 : 0
      case "center": return 1
      case "right":  return isOpponent ? 0 : 2
      default:       return -1
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
      case "effect_modifier_added":
        await this.animateModifierAdded(log)
        break
      case "effect_heal":
        await this.animateHeal(log)
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
    let damageAnim = Promise.resolve()

    // ダメージ情報の処理
    if (log.details.target_type === "unit" && log.details.target_card_id) {
        damageAnim = this.delay(300).then(() => 
            this.animateDamage({
                details: {
                    card_id: log.details.target_card_id,
                    amount: log.details.damage,
                    current_hp: log.details.target_hp // サーバーから返却される想定
                }
            })
        )
    } else if (log.details.target_type === "player" && log.details.target_player_id) {
        // プレイヤーへの攻撃の場合も数値を出す
        damageAnim = this.delay(300).then(() => this.animatePlayerDamage(log))
    }

    return Promise.all([attackAnim, damageAnim])
  }

  async animateDamage(log) {
    const cardId = log.details.card_id
    const amount = log.details.amount
    const currentHp = log.details.current_hp

    const cardEl = document.querySelector(`#game-card-${cardId}`)
    if (!cardEl) return

    this._ensureActive(cardEl)
    this._showFloatingNumber(cardEl, `-${amount}`, "damage-number")

    if (currentHp !== undefined) {
      // カードのHPをカウントダウン更新
      cardEl.dispatchEvent(new CustomEvent("game--card:update-hp", {
        detail: { newValue: currentHp }
      }))
    }

    // カードの振動演出
    return this.applyAnimation(cardEl, "animate-damage", 1000)
  }

  async animatePlayerDamage(log) {
    const targetPlayerId = log.details.target_player_id
    const damage = log.details.damage
    const currentHp = log.details.target_hp 
    const currentSan = log.details.target_san 

    const targetUserId = this._findUserIdByPlayerId(targetPlayerId)
    if (!targetUserId) return

    const targetEl = document.querySelector(`[data-game--countdown-user-id-value="${targetUserId}"] .hero-portrait-wrapper`)
    if (targetEl) {
        this._showFloatingNumber(targetEl, `-${damage}`, "damage-number")
    }

    // StatusBarへ更新通知
    if (currentHp !== undefined) {
        window.dispatchEvent(new CustomEvent("game--status:update-hp", {
            detail: { userId: parseInt(targetUserId), newValue: currentHp }
        }))
    }
    if (currentSan !== undefined) {
        window.dispatchEvent(new CustomEvent("game--status:update-san", {
            detail: { userId: parseInt(targetUserId), newValue: currentSan }
        }))
    }
  }

  async animateDeath(log) {
    const cardId = log.details.card_id
    const cardEl = document.querySelector(`#game-card-${cardId}`)
    if (!cardEl) return
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
    const cardName = log.details.card_name || "SPELL CARD" // サーバーから渡ってくる想定
    const keyCode = log.details.key_code 
    // サーバーから完全なアセットパス (/assets/cards/foo-digest.png) が送られてくる
    const imagePath = log.details.image_path || "/assets/cards/card_back_ancient.png"
    const ownerPlayerId = log.details.owner_player_id
    
    // 現在のプレイヤーIDを取得 (Stimulus Value)
    const currentPlayerId = this.currentPlayerIdValue
    const isSelf = (ownerPlayerId === currentPlayerId)

    // 1. Cut-In Animation
    const cutInContainer = document.createElement("div")
    cutInContainer.className = "spell-cut-in-container"
    cutInContainer.classList.add(isSelf ? "is-self" : "is-opponent")

    cutInContainer.innerHTML = ""

    const bgEl = document.createElement("div")
    bgEl.className = "spell-cut-in-bg"
    bgEl.style.backgroundImage = `url('${encodeURI(imagePath)}')`
    cutInContainer.appendChild(bgEl)

    const contentEl = document.createElement("div")
    contentEl.className = "spell-cut-in-content"

    const imageEl = document.createElement("div")
    imageEl.className = "spell-cut-in-image"
    imageEl.style.backgroundImage = `url('${encodeURI(imagePath)}')`

    const textEl = document.createElement("div")
    textEl.className = "spell-cut-in-text"
    textEl.textContent = cardName

    contentEl.appendChild(imageEl)
    contentEl.appendChild(textEl)
    cutInContainer.appendChild(contentEl)
    document.body.appendChild(cutInContainer)
    
    // Trigger Animation
    // 少し遅らせてアニメーション開始（DOM追加後のreflowを待つ意図）
    requestAnimationFrame(() => requestAnimationFrame(() => cutInContainer.classList.add("animate")))

    // 2. Target Highlighting (タイミングを少し遅らせる)
    this.delay(500).then(() => {
        this._highlightTargets(log)
    })

    // 3. Wait and Cleanup
    await this.delay(2000)
    cutInContainer.remove()
  }

  _highlightTargets(log) {
      const details = log.details
      let targets = []

      // 複数対象 (target_ids) があれば優先、なければ単体 (target_id)
      const targetIds = details.target_ids || (details.target_id ? [details.target_id] : [])
      const targetType = details.target_type || "unit"

      if (targetType === "unit") {
          targetIds.forEach(id => {
              const el = document.querySelector(`#game-card-${id}`)
              if (el) {
                  targets.push(el)
              } else {
                  console.warn(`[DEBUG] Target unit not found: #game-card-${id}`)
              }
          })
      } else if (targetType === "player") {
           // プレイヤー対象の場合 (target_ids には player_id が入っている想定)
           targetIds.forEach(playerId => {
               const userId = this._findUserIdByPlayerId(playerId)
               if (userId) {
                   const el = document.querySelector(`[data-game--countdown-user-id-value="${userId}"] .hero-portrait-wrapper`)
                   if (el) {
                        targets.push(el)
                   } else {
                        console.warn(`[DEBUG] Target player element not found for userId: ${userId}`)
                   }
               } else {
                   console.warn(`[DEBUG] UserId not found for playerId: ${playerId}`)
               }
           })
      }
      
      
      if (targets.length === 0) return

      // Apply Glow
      targets.forEach(el => {
          el.classList.add("animate-target-glow")
          // Force layout reflow to ensure animation triggers if re-added
          void el.offsetWidth 
      })

      // Remove Glow after a while
      setTimeout(() => {
          targets.forEach(el => el.classList.remove("animate-target-glow"))
      }, 1500)
  }

  async animatePayCost(log) {
    const userId = log.details.user_id
    const newSan = log.details.current_san
    const amount = log.details.amount

    // StatusBarに対してカウントダウン通知
    // StatusBarに対してカウントダウン通知
    if (newSan !== undefined) {
        window.dispatchEvent(new CustomEvent("game--status:update-san", {
            detail: { userId, newValue: newSan }
        }))
    }

    // SANコストの支払いでも数値を出す
    const targetEl = document.querySelector(`[data-game--countdown-user-id-value="${userId}"] .hero-portrait-wrapper`)
    if (targetEl && amount > 0) {
        this._showFloatingNumber(targetEl, `-${amount}`, "damage-number")
    }

    await this.delay(300)
  }

  async animateModifierAdded(log) {
    const cardId = log.details.target_id
    const modifierType = log.details.modifier_type
    const currentAttack = log.details.current_attack
    const currentHp = log.details.current_hp

    const cardEl = document.querySelector(`#game-card-${cardId}`)
    if (!cardEl) return

    this._ensureActive(cardEl)

    if (modifierType && modifierType.includes("attack") && currentAttack !== undefined) {
         cardEl.dispatchEvent(new CustomEvent("game--card:update-attack", {
             detail: { newValue: currentAttack }
         }))
    }
    
    if (modifierType && modifierType.includes("hp") && currentHp !== undefined) {
         cardEl.dispatchEvent(new CustomEvent("game--card:update-hp", {
             detail: { newValue: currentHp }
         }))
    }
    
    // 汎用バフエフェクト
    return this.applyAnimation(cardEl, "animate-buff", 800)
  }

  async animateHeal(log) {
    const cardId = log.details.target_id
    const amount = log.details.amount
    const newHp = log.details.new_hp
    const cardEl = document.querySelector(`#game-card-${cardId}`)
    
    if (!cardEl) return

    this._ensureActive(cardEl)
    this._showFloatingNumber(cardEl, `+${amount}`, "heal-number")

    if (newHp !== undefined) {
         cardEl.dispatchEvent(new CustomEvent("game--card:update-hp", {
             detail: { newValue: newHp }
         }))
    }

    return this.applyAnimation(cardEl, "animate-buff", 800)
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

  _showFloatingNumber(el, text, className) {
    if (!el || !text) return

    const numberEl = document.createElement("div")
    numberEl.className = className
    numberEl.textContent = text
    
    el.appendChild(numberEl)
    
    // アニメーション終了後に削除
    setTimeout(() => {
        numberEl.remove()
    }, 1500)
  }

  _findUserIdByPlayerId(playerId) {
    const selector = `[data-game--countdown-player-id-value="${playerId}"]`
    const el = document.querySelector(selector)
    
    if (!el) {
        // デバッグ: 見つからない場合、DOMにあるIDを全てリストアップする
        const all = document.querySelectorAll('[data-game--countdown-player-id-value]')
        const availableIds = Array.from(all).map(e => e.getAttribute('data-game--countdown-player-id-value'))
        console.warn(`[DEBUG] _findUserIdByPlayerId failed for ${playerId}. Available IDs in DOM:`, availableIds)
        return null
    }
    
    // Datasetプロパティアクセスの互換性問題を避けるため getAttribute を使用
    const userId = el.getAttribute("data-game--countdown-user-id-value")
    if (!userId) {
        console.warn(`[DEBUG] Element found for ${playerId} but userId is missing.`, el)
    }
    return userId
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
