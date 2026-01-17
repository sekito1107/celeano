class MatchmakingController < ApplicationController
  def create
    deck_type = current_user.selected_deck
    game = current_user.join_matchmaking!(deck_type)

    if game
      redirect_to matchmaking_path(matched: true, game_id: game.id), status: :see_other
    else
      redirect_to matchmaking_path, status: :see_other
    end
  end

  def show
    @matched = params[:matched] == "true"
    @game_id = params[:game_id]

    if @game_id
      game = current_user.games.find_by(id: @game_id)
      player = game&.game_players&.find_by(user: current_user)
      @opponent = player&.opponent&.user
    end
  end

  def destroy
    current_user.leave_matchmaking!
    redirect_to lobby_path
  end
end
