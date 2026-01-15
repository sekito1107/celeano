class TriggerPlayEffect
  include Interactor

  def call
    game_card = context.game_card
    return unless game_card.has_effect?(:on_play)

    game_card.trigger(:on_play, context.target)
  end
end
