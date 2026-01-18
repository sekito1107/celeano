class CardPlaysController < ApplicationController
  include GameContextLoader
  include GameActionHelper

  def create
    game_card = @game_player.game_cards.find_by(id: params[:game_card_id])
    unless game_card
      return handle_game_action(
        GameActionResult.failure(message: "指定されたカードが見つかりません"),
        status: :not_found
      )
    end

    result = PlayCard.call(
      game: @game,
      turn: @turn,
      game_player: @game_player,
      game_card: game_card,
      position: params[:position],
      target_id: params[:target_id]
    )

    handle_game_action(result, success_message: "カードをプレイしました")
  end
end
