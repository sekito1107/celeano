import { Controller } from "@hotwired/stimulus"
import { api } from "utils/api"

// Connects to data-controller="game--board"
export default class extends Controller {
  static targets = ["preview"]
  static values = {
    gameId: String
  }

  connect() {
    this.selectedCardId = null
    this.selectedCardType = null
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
    }
  }

  // 選択解除ヘルパー
  deselectAll() {
    this.element.querySelectorAll('[data-controller="game--card"]').forEach(el => {
        el.setAttribute("data-game--card-selected-value", "false")
    })
    this.selectedCardId = null
    this.selectedCardType = null

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
            window.location.reload()
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
        
        if (response.status === "success") {
            window.location.reload()
        }
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
            window.location.reload()
        }
    } catch (error) {
        console.error("Cancel failed:", error)
        // 必要なら通知
    }
  }
}
