import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    hp: Number,
    attack: Number,
    max: Number,
    userId: Number 
  }
  static targets = ["hp", "attack", "bar"]

  connect() {
    this.hpDisplay = this.hpValue
    this.attackDisplay = this.attackValue
  }

  // 外部からの更新（StatusBar等） - HPのみサポート維持
  updateFromEvent(event) {
    const { userId, newValue } = event.detail
    // 自分のStatusBarでなければ無視
    if (this.hasUserIdValue && this.userIdValue !== userId) return
    
    this.updateHp({ detail: { newValue } })
  }

  // カード自身のHP更新
  updateHp(event) {
     const { newValue } = event.detail
     this.animateTo(this.hpTarget, this.hpDisplay, newValue, (v) => {
       this.hpDisplay = v
       this.hpTarget.textContent = v
       
       if (this.hasBarTarget && this.hasMaxValue) {
         const max = this.maxValue || 0
         const percentage = max > 0 ? (v / max) * 100 : 0
         this.barTarget.style.width = `${percentage}%`
       }
     })
     this.hpValue = newValue // Sync value
  }

  // 攻撃力更新
  updateAttack(event) {
    const { newValue } = event.detail
    this.animateTo(this.attackTarget, this.attackDisplay, newValue, (v) => {
      this.attackDisplay = v
      this.attackTarget.textContent = v
    })
    this.attackValue = newValue // Sync value
  }

  animateTo(element, start, end, updateCallback) {
    if (start === end) return

    const diff = end - start
    const duration = 1000
    const startTime = performance.now()

    // アニメーション開始：拡大
    if (element) {
      element.classList.add("animate-pop-scale")
    }

    const step = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)
      const current = Math.round(start + diff * progress)

      updateCallback(current)

      if (progress < 1) {
        requestAnimationFrame(step)
      } else {
        // アニメーション終了
        updateCallback(end)
        
        if (element) {
          element.classList.remove("animate-pop-scale")
        }
      }
    }

    requestAnimationFrame(step)
  }
}
