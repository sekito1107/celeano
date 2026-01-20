import { Controller } from "@hotwired/stimulus"
import { api } from "utils/api"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="game--board"
export default class extends Controller {
  static targets = ["preview"]
  static values = {
    gameId: String
  }

  connect() {
    this.selectedCardId = null
    this.selectedCardType = null

    this.consumer = createConsumer()
    this.channel = this.consumer.subscriptions.create(
      { channel: "GameChannel", game_id: this.gameIdValue },
      {
        received: this.handleMessage.bind(this)
      }
    )

    // Turbo Streamの一時停止制御
    this.onBeforeStreamRender = this.handleBeforeStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.onBeforeStreamRender)

    // リフレッシュフラグの確実なリセット
    this.onTurboLoad = () => { this._refreshing = false }
    document.addEventListener("turbo:load", this.onTurboLoad)
  }

  disconnect() {
    this.channel?.unsubscribe()
    this.consumer?.disconnect()
    document.removeEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
    document.removeEventListener("turbo:load", this.onTurboLoad)
  }

  handleBeforeStreamRender(event) {
    const animationController = this.application.getControllerForElementAndIdentifier(this.element, "game--animation")
    if (animationController && animationController.isAnimating) {
        event.preventDefault()
        
        let resolved = false
        // アニメーション完了後に再開
        const resumeRender = () => {
             if (resolved) return
             resolved = true
             clearTimeout(timeoutId)
             this.element.removeEventListener("game--animation:finished", resumeRender)
             event.detail.render(event.detail.newStream)
        }
        this.element.addEventListener("game--animation:finished", resumeRender)
        
        // フォールバック: 10秒後に強制的にレンダリング
        const timeoutId = setTimeout(resumeRender, 10000)
    }
  }

  async handleMessage(data) {
    if (data.type === "game_update") {
      if (data.battle_logs && data.battle_logs.length > 0) {
        // アニメーション完了後にリロードしたいため、完了を待つリスナーを一度だけセット
        if (data.board_update) {
          const onFinished = () => {
            this.element.removeEventListener("game--animation:finished", onFinished)
            // フェーズ完了時は必ずリロードして最新の盤面（新ターン等）にする
            this.refreshBoard()
          }
          this.element.addEventListener("game--animation:finished", onFinished)
        }
        
        // アニメーション開始
        const logs = Array.isArray(data.battle_logs) ? data.battle_logs : []
        this.dispatch("logs-received", { detail: { logs } })
      } else if (data.board_update) {
        this.refreshBoard()
      }
    } else if (data.type === "ready_update") {
      // 準備状態の変更をリアルタイムに反映（リロードなしでボタン外見などを変える）
      // 面倒ならここでも refreshBoard() して良いが、
      // フェーズ移行時（game_update）と重まらないように注意が必要。
      // 今回は安全のため、フェーズ移行（battle_logsがある場合）でなければリロードする
      this.refreshBoard()
    }
  }

  refreshBoard() {
    // アニメーション中ならリロードを保留する
    const animationController = this.application.getControllerForElementAndIdentifier(this.element, "game--animation")
    if (animationController && animationController.isAnimating) {
        if (!this._waitingForAnimation) {
            this._waitingForAnimation = true
            const onFinished = () => {
                this.element.removeEventListener("game--animation:finished", onFinished)
                this._waitingForAnimation = false
                this.refreshBoard()
            }
            this.element.addEventListener("game--animation:finished", onFinished)
        }
        return
    }

    // すでにリロード処理中ならスキップ
    if (this._refreshing) return
    this._refreshing = true

    if (window.Turbo) {
      window.Turbo.visit(window.location.href, { action: "replace" })
    } else {
      window.location.reload()
    }
  }

  // 詳細表示の更新（イベント受信）
  showDetail(event) {
    const { cardId, html } = event.detail
    const previewContainer = this.hasPreviewTarget ? this.previewTarget : null
    
    if (previewContainer && html) {
        // もしピン留めされてたら更新しない（自分以外）
        if (previewContainer.dataset.pinnedBy && previewContainer.dataset.pinnedBy !== cardId) {
            return
        }
        
        previewContainer.innerHTML = html
        previewContainer.classList.add("active")
    }
  }

  // 詳細非表示に更新
  hideDetail() {
    const previewContainer = this.hasPreviewTarget ? this.previewTarget : null
    if (!previewContainer) return

    // もしピン留めされてたら非表示にしない
    if (previewContainer.dataset.pinnedBy) {
        return
    }

    previewContainer.classList.remove("active")
    previewContainer.innerHTML = ""
  }


  // カード選択（イベント受信）
  selectCard(event) {
    const { cardId, cardType, element } = event.detail
    
    // 既存の選択を解除
    if (this.selectedCardId && this.selectedCardId !== cardId) {
        this.deselectAll()
    }

    // トグル動作
    if (this.selectedCardId === cardId) {
        this.selectedCardId = null
        this.selectedCardType = null
        element.setAttribute("data-game--card-selected-value", "false")
        this.element.classList.remove("has-selection")
        this._clearHighlights()
        
        
        // ピン留め解除
        if (this.hasPreviewTarget) {
            const previewContainer = this.previewTarget
            delete previewContainer.dataset.pinnedBy
            previewContainer.classList.remove("pinned")
            this.hideDetail() // 自動的に隠す
        }
    } else {
        this.selectedCardId = cardId
        this.selectedCardType = cardType
        element.setAttribute("data-game--card-selected-value", "true")
        this.element.classList.add("has-selection")
        
        // ピン留め
        if (this.hasPreviewTarget) {
            const previewContainer = this.previewTarget
            previewContainer.dataset.pinnedBy = cardId
            previewContainer.classList.add("pinned")

            // HTMLを強制的にセット（マウスアウトしても消えないように）
            if (event.detail.detailHtml) {
                previewContainer.innerHTML = event.detail.detailHtml
                previewContainer.classList.add("active") // Ensure active is set
            }
        }

        // ターゲット候補のハイライト
        // dataset property conversion can be tricky with double hyphens. Using getAttribute for safety.
        const targetTypeHint = element.getAttribute("data-game--card-target-type-hint-value")
        
        if (targetTypeHint) {
            this._highlightValidTargets(targetTypeHint)
        }
    }
  }

  // 選択解除ヘルパー
  deselectAll() {
    this.element.querySelectorAll('[data-controller~="game--card"]').forEach(el => {
        el.setAttribute("data-game--card-selected-value", "false")
    })
    this.selectedCardId = null
    this.selectedCardType = null
    this.element.classList.remove("has-selection")
    
    this._clearHighlights()

    if (this.hasPreviewTarget) {

        const previewContainer = this.previewTarget
        delete previewContainer.dataset.pinnedBy
        previewContainer.classList.remove("pinned")
        this.hideDetail()
    }
  }

  // カードプレイ（クリック版）
  async playCard(event) {
    // 選択されていない場合はバブリングさせて deselectAll へ
    if (!this.selectedCardId) return



    const targetPosition = event.currentTarget.dataset.position
    
    // Spellの場合はCardIDをターゲットにする場合がある
    // Unitの場合は位置必須
    
    let targetId = this._resolveTargetId(event.currentTarget)
    
    // バリデーション: ユニットは位置指定必須（なければ無効プレイとしてバブリングさせる）
    if (this.selectedCardType === "unit" && !targetPosition) return
    
    // 有効なプレイと判断したらイベントを止める
    event.preventDefault()
    event.stopPropagation()
    
    await this.performCardPlay(this.selectedCardId, targetPosition, targetId)
    this.deselectAll()
  }

  // ドラッグ始点 (Cancellation)
  dragstart(event) {
    const target = event.target.closest('[draggable="true"]')
    if (target && target.dataset.cardType === "cancel") {
        event.dataTransfer.setData("text/plain", target.dataset.cardId)
        event.dataTransfer.setData("application/x-card-type", "cancel")
        event.dataTransfer.effectAllowed = "move"
    } else {
        // 通常のカードドラッグ（手札など）は他のコントローラーで処理あるいはここで処理
    }
  }

  // ドラッグオーバー（ドロップ許可判定）
  dragover(event) {
    event.preventDefault()
    event.stopPropagation() // Prevent bubbling
    event.dataTransfer.dropEffect = "move"
  }

  // ドロップ＆プレイ
  async drop(event) {
    event.preventDefault()
    event.stopPropagation() // Prevent bubbling to parent slot

    const cardId = event.dataTransfer.getData("text/plain")
    const cardType = event.dataTransfer.getData("application/x-card-type")
    
    // キャンセルカードのドロップ（手札エリアへのドロップを想定）
    if (cardType === "cancel") {
        if (!cardId) return

        // ドロップ先が Handエリア かどうか判定
        if (event.currentTarget.closest('.hand-container') || event.currentTarget.classList.contains('hand-container')) {
             await this.performCardCancel(cardId)
             return
        }
        // それ以外（フィールド内の移動など）は現状サポートしないので無視
        return
    }

    const targetPosition = event.currentTarget.dataset.position
    let targetId = this._resolveTargetId(event.currentTarget)

    if (!cardId) return

    // バリデーション
    if (cardType === "unit" && !targetPosition) return
    
    await this.performCardPlay(cardId, targetPosition, targetId)
  }

  // キャンセル（ダブルクリック）
  async cancelCard(event) {
      event.preventDefault()
      event.stopPropagation()
      const cardId = event.currentTarget.dataset.cardId
      if (cardId) {
          await this.performCardCancel(cardId)
      }
  }

  // TargetID解決ヘルパー
  _resolveTargetId(element) {
    let targetId = this.getTargetId(element)

    // スロット自体にIDがない場合、内部のカードコンポーネントを探す
    if (!targetId) {
        const cardElement = element.querySelector('[data-game--card-id-value]')
        if (cardElement) {
             targetId = cardElement.getAttribute('data-game--card-id-value')
        }
    }
    return targetId
  }

  // API実行用プライベートメソッド
  async performCardPlay(cardId, position, targetId = null) {
    try {
        const body = { 
            game_card_id: cardId,
            position: position,
            target_id: targetId
        }
        
        // スペルの場合はpositionを送らない、あるいはnilとして送る
        // controller側でnil許容しているはず

        const response = await api.post(`/games/${this.gameIdValue}/card_plays`, body)
        
        if (response.status === "success") {
            // 成功したらリロード（PR 19でTurbo化）
            this.refreshBoard()
        }
    } catch (error) {
        // Log failure but do not alert user (e.g. invalid move)
    }
  }

  // ターゲットID取得ヘルパー
  getTargetId(element) {
    if (element.hasAttribute("data-game--card-id-value")) {
        return element.getAttribute("data-game--card-id-value")
    }
    return null
  }

  // 準備完了トグル
  async ready(event) {
    try {
        const response = await api.post(`/games/${this.gameIdValue}/ready_states`, {})
        // 成功してもリロードしない。ActionCableの ready_update または game_update を待つ。
    } catch (error) {
        console.error("Ready toggle failed:", error)
        alert(error.message || "処理に失敗しました")
    }
  }
  // キャンセルAPI実行
  async performCardCancel(cardId) {
    try {
        const response = await api.delete(`/games/${this.gameIdValue}/card_plays/${cardId}`)
        
        if (response.status === "success") {
            this.refreshBoard()
        }
    } catch (error) {
        console.error("Cancel failed:", error)
        // 必要なら通知
    }
  }

  // --- Highlighting Helpers ---

  _highlightValidTargets(hint) {
    if (!hint || hint === "none") return

    let selector = ""
    switch (hint) {
      case "slot":
        // 自分のフィールドの空きスロット (厳密には .play-mat-opponent の外側にある .field-slot で、かつ .empty-slot を含むもの)
        // または子要素がないスロット
        selector = ".play-mat:not(.play-mat-opponent) .field-slot:has(.empty-slot), .play-mat:not(.play-mat-opponent) .field-slot:empty"
        break
      case "enemy_unit":
        // 相手のユニット (カードがあるスロット)
        selector = ".play-mat-opponent .field-slot .card-wrapper"
        break
      case "ally_unit":
        // 自分のユニット
        selector = ".play-mat:not(.play-mat-opponent) .field-slot .card-wrapper"
        break
      case "any_unit":
        // 敵味方問わず全てのユニット
        selector = ".play-mat:not(.play-mat-opponent) .field-slot .card-wrapper, .play-mat-opponent .field-slot .card-wrapper"
        break
      case "enemy_board":
        // 相手フィールド全体 (ユニットゾーンのみ)
        selector = ".play-mat-opponent .field-slots-area"
        break
      case "ally_board":
        // 自分フィールド全体 (ユニットゾーンのみ)
        selector = ".play-mat:not(.play-mat-opponent) .field-slots-area" 
        break
    }

    if (selector) {
      this.element.querySelectorAll(selector).forEach(el => {
        el.classList.add("target-highlight")
      })
    }
  }

  _clearHighlights() {
    this.element.querySelectorAll(".target-highlight").forEach(el => {
      el.classList.remove("target-highlight")
    })
  }
}
