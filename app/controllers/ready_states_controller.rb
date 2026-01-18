class ReadyStatesController < ApplicationController
  include GameContextLoader
  include GameActionHelper

  def create
    result = ToggleReady.call(
      game_player: @game_player,
      turn: @turn
    )

    message = result.success? ? (result.phase_completed ? "ターン終了" : "準備完了状態を変更しました") : nil
    handle_game_action(result, success_message: message)
  end
end
