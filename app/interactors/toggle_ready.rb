# プレイヤーの準備完了状態を切り替える
# 両プレイヤーが準備完了になった場合、PlanningPhaseを実行する
class ToggleReady
  include Interactor

  def call
    game_player = context.game_player
    game = game_player.game
    turn = context.turn

    ActiveRecord::Base.transaction do
      # 競合を防ぐためにgameレコードをロック
      game.lock!

      # 準備完了状態を切り替え
      game_player.update!(ready: !game_player.ready)

      # 両プレイヤーが準備完了かチェック
      if all_players_ready?(game)
        # PlanningPhaseを実行
        result = PlanningPhase.call(game: game, turn: turn)

        context.next_turn = result.next_turn if result.next_turn
        context.fail!(message: result.message) if result.failure?

        context.phase_completed = true
      else
        context.phase_completed = false
      end
    end
  end

  private

  def all_players_ready?(game)
    game.game_players.reload.all?(&:ready)
  end
end
