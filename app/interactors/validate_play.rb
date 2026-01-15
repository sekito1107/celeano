class ValidatePlay
  include Interactor

  def call
    return if context.game.finished?

    turn = context.turn
    card = context.game_card.card
    user = context.game_player.user

    unless turn.planning?
      context.fail!(message: "現在はカードをプレイできるフェーズではありません")
    end

    nonce = Move.joins(:turn).where(turns: { game_id: context.game.id }).count
    actual_cost = Dice.roll(card.cost, context.game.seed, nonce)

    context.paid_cost = actual_cost

    if card.unit?
      validate_unit_play(turn, user)
    end
  end

  private

  def validate_unit_play(turn, user)
    validate_position_presence!
    validate_summon_limit!(turn, user)
    validate_slot_availability!
  end

  def validate_position_presence!
    if context.position.nil?
      context.fail!(message: "ユニットカードの配置位置が指定されていません")
    end
  end

  def validate_summon_limit!(turn, user)
    if turn.summon_limit_reached?(user)
      context.fail!(message: "ラウンド#{turn.turn_number}の召喚上限に達しています")
    end
  end

  def validate_slot_availability!
    game_player = context.game_player
    position = context.position

    if slot_occupied?(game_player, position)
      context.fail!(message: "そのスロット（#{position}）は既に使用されています")
    end
  end

  def slot_occupied?(game_player, position)
    # ボード上または予約中のカードをチェック
    game_player.game_cards
               .where(position: position)
               .where(location: [ :board, :resolving ])
               .exists?
  end
end
