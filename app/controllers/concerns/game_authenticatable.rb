# frozen_string_literal: true

module GameAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_game_access!
  end

  private

  def authenticate_game_access!
    @game = Game.find_by(id: params[:id])

    unless @game
      redirect_to root_path, alert: "指定されたゲームは見つかりませんでした。"
      return
    end

    # Future: If implementing spectator mode, modify this check.
    # Currently, strict access for participants only.
    unless @game.game_players.exists?(user: current_user)
      redirect_to root_path, alert: "このゲームに参加する権限がありません。"
    end
  end
end
