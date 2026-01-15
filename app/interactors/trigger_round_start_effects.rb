class TriggerRoundStartEffects
  include Interactor

  def call
    game = context.game

    ActiveRecord::Base.transaction do
      board_cards = game.game_cards.includes(:card).where(location: :board).to_a

      board_cards.each do |game_card|
        next unless game_card.reload.location_board?
        game_card.trigger(:on_round_start)
      end
    end
  end
end
