# ゲーム開始時の初期化処理を行うOrganizer
# 1. デッキのセットアップ（YAMLからGameCard生成）
# 2. 最初のターンの作成（ログ記録に必要）
# 3. デッキのシャッフル
# 4. 初期手札の配布（4枚）
class StartGame
  include Interactor::Organizer

  organize SetupDeck, CreateFirstTurn, ShuffleDeck, DrawInitialHands
end
