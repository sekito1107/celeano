# ドローフェーズを処理するOrganizer
# 両プレイヤーがカードを1枚ドローし、手札上限をチェック
class DrawPhase
  include Interactor::Organizer

  organize DrawCards, EnforceHandLimit
end
