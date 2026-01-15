# HP0以下のユニットを破壊して墓地へ送る
class ProcessDeaths
  include Interactor

  def call
    game = context.game

    context.fail!(message: "Game context is missing") unless game
    context.fail!(message: "Turn context is missing") unless context.turn

    dead_units = game.game_cards.includes(:card).where(location: :board).where(current_hp: ...1).to_a

    ActiveRecord::Base.transaction do
      dead_units.each do |game_card|
        # on_death効果をトリガー
        game_card.trigger(:on_death)

        # 墓地へ移動
        game_card.discard!

        game_card.log_event!(:unit_death, {
          card_id: game_card.id,
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          owner_player_id: game_card.game_player_id
        })
      end
    end

    context.dead_units = dead_units
  end
end
