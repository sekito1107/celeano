class TriggerPlayEffect
  include Interactor

  def call
    game_card = context.game_card
    game_card = context.game_card
    # スペルは解決フェーズで発動するため、ここでは発動しない
    return if game_card.card.spell?

    return unless game_card.has_effect?(:on_play)

    game_card.trigger(:on_play, context.target)
  end
end
