class CreateMove
  include Interactor

  def call
    move = build_move

    if move.save
      context.move = move
    else
      context.fail!(message: error_message(move))
    end
  end

  private

  def build_move
    context.turn.moves.build(
      user: context.game_player.user,
      game_card: context.game_card,
      action_type: resolve_action_type,
      position: resolve_position
    )
  end

  def resolve_action_type
    card.unit? ? :play : :spell
  end

  def resolve_position
    card.unit? ? context.position : nil
  end

  def card
    context.game_card.card
  end

  def error_message(move)
    "カードの配置に失敗しました: #{move.errors.full_messages.join(', ')}"
  end
end
