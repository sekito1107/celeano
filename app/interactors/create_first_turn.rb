# 最初のターンを作成する
class CreateFirstTurn
  include Interactor

  def call
    game = context.game

    turn = game.turns.create!(
      turn_number: 1,
      status: :planning
    )

    context.turn = turn
  end
end
