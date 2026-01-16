import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  connect() {
    this.quotes = [
      "ビヤーキーに乗る際は、黄金の蜂蜜酒を忘れてはならない。",
      "ふんぐるい むぐるうなふ くとぅるう るるいえ うがふなぐる ふたぐん",
      "深淵を覗くとき、深淵もまたこちらを覗いているのだ。",
      "恐怖こそが、最も古く、最も強い感情である。",
      "その死せるものは、永遠に横たわることなし。",
      "名状しがたきものが、そこに居た。",
      "いあ！ いあ！ はすたあ！",
      "窓に！ 窓に！",
      "テケリ・リ！ テケリ・リ！",
      "もはや、逃げる場所など何処にもない。",
      "星辰が正しい位置についたとき、彼らは蘇るだろう。",
      "我々はただ、その時を待つのみ。",
      "狂気だけが、唯一の救済となるかもしれない。",
      "古代の神々は、死んではいない。ただ眠っているだけだ。",
      "その書物を開いてはならない。そこには禁断の知識が記されている。",
      "インスマスには近づくな。あそこの住人は何かがおかしい。",
      "壁の中から音が聞こえる… ネズミではない、もっと大きな何かが…",
      "銀の鍵が、幻夢境への扉を開く。",
      "ニャルラトホテプ… 這い寄る混沌…",
      "サツァ… ヨグ・ソトース…",
      "この宇宙において、人類はあまりにも無力な存在に過ぎない。",
      "正気を保つためには、見ざる、聞かざる、知らざるが一番だ。"
    ]
    // Randomize start index
    this.currentIndex = Math.floor(Math.random() * this.quotes.length)
    this.textTarget.textContent = this.quotes[this.currentIndex] // Initial text update to random
    
    this.startRotation()
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
    if (this.fadeTimeout) clearTimeout(this.fadeTimeout)
  }

  startRotation() {
    this.timer = setInterval(() => {
      this.cycleText()
    }, 9000) // 9 seconds interval (3x original)
  }

  cycleText() {
    // Fade out
    this.textTarget.style.opacity = 0
    
    this.fadeTimeout = setTimeout(() => {
      if (!this.element.isConnected) return

      // Pick random next quote instead of sequential to keep it fresh
      let nextIndex
      do {
        nextIndex = Math.floor(Math.random() * this.quotes.length)
      } while (nextIndex === this.currentIndex && this.quotes.length > 1)
      
      this.currentIndex = nextIndex
      this.textTarget.textContent = this.quotes[this.currentIndex]
      // Fade in
      this.textTarget.style.opacity = 1
    }, 1000) // 1 second fade out/in (slower, more atmospheric)
  }
}
