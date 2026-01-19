module GameContextLoader
  extend ActiveSupport::Concern

  included do
    before_action :set_game_context
  end

  private

  def set_game_context
    @game = Game.find(params[:game_id])
    @game_player = @game.game_players.find_by!(user: current_user)
    @turn = @game.turns.order(turn_number: :desc).first
    @resolving_cards = @game.game_cards.includes(:card).where(location: "resolving", user: current_user).reject(&:unit?)
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to lobby_path, alert: "ゲームまたはプレイヤーが見つかりません" }
      format.json { render json: { status: "error", message: "Game or player not found" }, status: :not_found }
    end
  end
end
