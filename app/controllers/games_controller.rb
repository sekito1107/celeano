class GamesController < ApplicationController
  include GameAuthenticatable

  layout "game"

  def show
    # N+1対策: ゲームに関連するプレイヤー、カード、GameCardを事前にロード
    @game = Game.includes(game_players: { game_cards: :card }).find(params[:id])

    @game_player = @game.game_players.find { |gp| gp.user_id == current_user.id }
    @opponent_game_player = @game.game_players.find { |gp| gp.user_id != current_user.id }

    # GameAuthenticatable のチェックを通すためのインスタンス変数は再利用
    # (includes を使ってロードし直した @game を使うため)

    @resolving_cards = @game.game_cards.select(&:location_resolving?)
  end
end
