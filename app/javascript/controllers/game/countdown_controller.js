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
    // 自分のStatusBarでなければ無視
    if (this.hasUserIdValue && this.userIdValue !== userId) return
    
    this.animateTo(newValue)
  }

  // カード自身のHP更新など
  updateValue(event) {
     const { newValue } = event.detail
     this.animateTo(newValue)
  }

  animateTo(newValue) {
    if (this.displayValue === newValue) return

    const start = this.displayValue
    const diff = newValue - start
    const duration = 500
    const startTime = performance.now()

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
      }
    }

    requestAnimationFrame(step)
  }

  updateDisplay(value) {
    if (this.hasValueTarget) {
      if (this.hasMaxValue) {
        this.valueTarget.textContent = `${value} / ${this.maxValueValue}`
      } else {
        this.valueTarget.textContent = value
      }
    }

    if (this.hasBarTarget && this.hasMaxValueValue) {
      const percentage = (value / this.maxValueValue) * 100
      this.barTarget.style.width = `${percentage}%`
    }
  }
}
