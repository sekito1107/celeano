# 計画フェーズ完了後の処理を調整するOrganizer
# 1. ResolvePhase: 解決フェーズを実行
# 2. DrawPhase: ドローフェーズを実行（ゲーム終了時はスキップ）
# 3. CreateNextTurn: 次のターンを作成（ゲーム終了時はスキップ）
class PlanningPhase
  include Interactor::Organizer

  organize ResolvePhase, DrawPhase, CreateNextTurn

  around do |interactor|
    game = context.game
    turn = context.turn

    # 準備完了フラグをリセット
    game.game_players.update_all(ready: false)

    # 解決フェーズを開始
    turn.update!(status: :resolving)

    interactor.call
  end
end
