# 各プレイヤーに初期手札を4枚配る
class DrawInitialHands
  include Interactor

  INITIAL_HAND_SIZE = 4

  def call
    game = context.game

    ActiveRecord::Base.transaction do
      game.game_players.includes(:game_cards).each do |player|
        INITIAL_HAND_SIZE.times do
          player.draw_card!
        end
      end
    end
  end
end
