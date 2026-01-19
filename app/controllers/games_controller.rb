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

    # 現在のターンを取得
    @current_turn = @game.turns.includes(moves: { game_card: :card }).find_by(turn_number: @game.current_turn_number)

    # 現在のターンのMoveを取得してコストを紐付ける
    @resolving_cards = @game.game_cards.select do |card|
      card.location_resolving? && card.user_id == current_user.id && !card.unit?
    end
  end
end
