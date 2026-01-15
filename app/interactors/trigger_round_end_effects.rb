class TriggerRoundEndEffects
  include Interactor

  def call
    game = context.game

    ActiveRecord::Base.transaction do
      trigger_board_end_effects(game)
      trigger_graveyard_effects(game)
    end
  end

  private

  def trigger_board_end_effects(game)
    board_cards = game.game_cards.includes(:card).where(location: :board).to_a

    board_cards.each do |game_card|
      next unless game_card.reload.location_board?
      game_card.trigger(:on_round_end)
    end
  end

  def trigger_graveyard_effects(game)
    graveyard_cards = game.game_cards.includes(:card).where(location: :graveyard).to_a

    graveyard_cards.each do |game_card|
      next unless game_card.reload.location_graveyard?
      game_card.trigger(:on_graveyard)
    end
  end
end
