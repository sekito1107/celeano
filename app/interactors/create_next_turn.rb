# 次のターンを作成する
class CreateNextTurn
  include Interactor

  def call
    game = context.game
    current_turn = context.turn

    game.with_lock do
      # ゲームが終了している場合は何もしない
      return if game.finished?

      next_turn = game.turns.create!(
        turn_number: current_turn.turn_number + 1,
        status: :planning
      )

      current_turn.update!(status: :done)

      context.next_turn = next_turn
    end
  end
end
