# カードを引くステップ
module CardEffects
  module Steps
    class DrawCards < BaseStep
      # 使用例:
      #   draw_cards count: 2

      def call(context)
        count = params[:count] || 1
        return if count <= 0

        game_player = context.game_player
        deck_cards = game_player.game_cards
                                .where(location: :deck)
                                .order(:position_in_stack)
                                .limit(count)

        cards = []
        ActiveRecord::Base.transaction do
          hand_size = game_player.game_cards.where(location: :hand).count

          cards = deck_cards.to_a
          cards.each_with_index do |card, index|
            card.move_to_hand!(hand_size + index)
          end

          if cards.size < count
            game_player.game.check_deck_death!(game_player)
          end

          context.log_effect(:effect_draw, {
            count: cards.size,
            player_id: game_player.id
          })
        end
      end
    end
  end
end
