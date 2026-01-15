class TriggerRoundEffects
  include Interactor

  def call
    game = context.game
    context.fail!(message: "Game not found") unless game
    timing = context.timing || :on_round_start

    ActiveRecord::Base.transaction do
      board_cards = game.game_cards.includes(:card).where(location: :board).to_a

      board_cards.each do |game_card|
        next unless game_card.reload.location_board?
        game_card.trigger(timing)
      end

      if timing == :on_round_end
        graveyard_cards = game.game_cards.includes(:card).where(location: :graveyard).to_a
        graveyard_cards.each do |game_card|
          next unless game_card.reload.location_graveyard?
          game_card.trigger(:on_graveyard)
        end
      end
    end
  end
end
