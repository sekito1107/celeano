import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game--card"
export default class extends Controller {
  static values = {
    id: String,
    type: String, // "unit" or "spell"
    selected: Boolean,
    detailHtml: String
  }

  connect() {
    this.element.setAttribute("draggable", "true")
  }

  // ホバー時に詳細表示イベントを発火
  mouseenter() {
    this.dispatch("showDetail", { 
        detail: { 
            cardId: this.idValue,
            html: this.detailHtmlValue 
        },
        bubbles: true 
    })
  }

  mouseleave() {
    this.dispatch("hideDetail", { bubbles: true })
  }

  // クリック時に選択イベントを発火
  click(event) {
    if (event.defaultPrevented) return
    event.stopPropagation() // 背景のdeselectAllを防ぐ
    
    this.dispatch("selectCard", {
      detail: { 
        cardId: this.idValue,
        cardType: this.typeValue,
        detailHtml: this.detailHtmlValue,
        element: this.element
      },
      bubbles: true
    })
  }

  dragstart(event) {
    event.dataTransfer.setData("text/plain", this.idValue)
    event.dataTransfer.setData("application/x-card-type", this.typeValue)
    event.dataTransfer.effectAllowed = "move"
    
    // ドラッグ中の見た目を少し変える（半透明など）
    this.element.classList.add("opacity-50")
  }

  dragend(event) {
    this.element.classList.remove("opacity-50")
  }

  // 選択状態のスタイル切り替え（親から呼ばれる想定、または自己完結）
  selectedValueChanged() {
    if (this.selectedValue) {
        this.element.classList.add("selected")
    } else {
        this.element.classList.remove("selected")
    }
  }
}
