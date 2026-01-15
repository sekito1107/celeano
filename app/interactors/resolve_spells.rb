class ResolveSpells
  include Interactor

  def call
    turn = context.turn

    return if turn.game.finished?

    spell_moves = turn.moves
                      .eager_load(game_card: :card, target_game_card: :card)
                      .where(action_type: :spell)

    spell_moves.each do |move|
      break if turn.game.reload.finished?

      game_card = move.game_card
      target = move.target_game_card

      ActiveRecord::Base.transaction do
        game_card.log_event!(:spell_activation, {
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          target_id: target&.id
        })

        game_card.trigger(:on_play, target)

        # スペルは効果発動後に墓地へ
        game_card.discard!
      end
    end
  end
end
