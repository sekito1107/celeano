class ProcessCardMovement
  include Interactor

  def call
    game_card = context.game_card
    card = game_card.card

    if card.unit?
      # ユニットは予約状態に（解決フェーズでボードに配置される）
      position = context.position
      context.fail!(message: "Position is required for unit") unless position
      game_card.reserve_to!(position)
    else
      # スペルも予約状態に（解決フェーズで効果発動後に墓地へ）
      game_card.update!(location: :resolving, position: nil, position_in_stack: nil)
    end
  end
end
