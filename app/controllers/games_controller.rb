class GamesController < ApplicationController
  include GameAuthenticatable

  layout "game"

  def show
    # N+1対策: ゲームに関連するプレイヤー、カード、GameCardを事前にロード
    @game = Game.with_full_details.find(params[:id])

    @game_player = @game.game_players.find { |gp| gp.user_id == current_user.id }
    @opponent_game_player = @game.game_players.find { |gp| gp.user_id != current_user.id }

    # GameAuthenticatable のチェックを通すためのインスタンス変数は再利用
    # (includes を使ってロードし直した @game を使うため)

    # 現在のターンを取得
    @current_turn = @game.turns.includes(moves: { game_card: { card: :keywords } }).find_by(turn_number: @game.current_turn_number)

    # 現在のターンのMoveを取得してコストを紐付ける
    # N+1対策: @game_player.game_cards (eager loaded) から取得
    @resolving_cards = @game_player.game_cards.select do |card|
      card.location_resolving? && !card.unit?
    end
  end
end
