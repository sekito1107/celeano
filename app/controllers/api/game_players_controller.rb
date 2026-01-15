module Api
  class GamePlayersController < ApplicationController
    before_action :set_game_player

    # PUT /api/games/:game_id/players/:id/deck
    # デッキを選択・変更する（ゲーム開始前のみ）
    def update_deck
      unless @game_player.game.matching?
        return render json: { error: "Cannot change deck after game started" }, status: :unprocessable_content
      end

      if @game_player.update(deck_type: deck_params[:deck_type])
        render json: { deck_type: @game_player.deck_type }
      else
        render json: { errors: @game_player.errors.full_messages }, status: :unprocessable_content
      end
    end

    private

    def set_game_player
      @game_player = current_user.game_players.where(game_id: params[:game_id]).find(params[:id])
    end

    def deck_params
      params.require(:game_player).permit(:deck_type)
    end
  end
end
