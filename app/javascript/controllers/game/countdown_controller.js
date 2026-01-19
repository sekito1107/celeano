import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    current: Number, 
    max: Number,
    userId: Number 
  }
  static targets = ["value", "bar"]

  connect() {
    this.displayValue = this.currentValue
  }

  // 外部からの更新（StatusBar等）
  updateFromEvent(event) {
    const { userId, newValue } = event.detail
    console.log("[DEBUG] CountdownController: updateFromEvent received", { userId, newValue, myUserId: this.userIdValue })
    
    // 自分のStatusBarでなければ無視
    if (this.hasUserIdValue && this.userIdValue !== userId) return
    
    this.animateTo(newValue)
  }

  // カード自身のHP更新など
  updateValue(event) {
     const { newValue } = event.detail
     console.log("[DEBUG] CountdownController: updateValue received", { newValue, currentDisplay: this.displayValue })
     this.animateTo(newValue)
  }

  animateTo(newValue) {
    if (this.displayValue === newValue) return

    const start = this.displayValue
    const diff = newValue - start
    const duration = 1000
    const startTime = performance.now()

    // アニメーション開始：拡大
    if (this.hasValueTarget) {
      this.valueTarget.classList.add("animate-pop-scale")
    }

    const step = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)
      const current = Math.round(start + diff * progress)

      this.displayValue = current
      this.updateDisplay(current)

      if (progress < 1) {
        requestAnimationFrame(step)
      } else {
        this.displayValue = newValue
        this.currentValue = newValue
        
        // アニメーション終了：元のサイズに戻す
        if (this.hasValueTarget) {
          this.valueTarget.classList.remove("animate-pop-scale")
        }
      }
    }

    requestAnimationFrame(step)
  }

  updateDisplay(value) {
    if (this.hasValueTarget) {
      // 常に現在値のみ表示（最大値はバーの計算にのみ使用）
      this.valueTarget.textContent = value
    }

    if (this.hasBarTarget && this.hasMaxValue) {
      const max = this.maxValue || 0
      const percentage = max > 0 ? (value / max) * 100 : 0
      this.barTarget.style.width = `${percentage}%`
    }
  }
}
