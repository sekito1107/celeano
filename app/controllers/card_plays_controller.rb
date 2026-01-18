class CardPlaysController < ApplicationController
  include GameContextLoader
  include GameActionHelper

  def create
    result = PlayCard.call(
      game: @game,
      turn: @turn,
      game_player: @game_player,
      game_card_id: params[:game_card_id],
      position: params[:position],
      target_id: params[:target_id]
    )

    handle_game_action(result, success_message: "カードをプレイしました")
  end
end
