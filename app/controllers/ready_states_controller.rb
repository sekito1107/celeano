class ReadyStatesController < ApplicationController
  include GameContextLoader
  include GameActionHelper

  def create
    result = ToggleReady.call(
      game_player: @game_player,
      turn: @turn
    )

    message = result.success? ? (result.phase_completed ? "ターン終了" : "準備完了状態を変更しました") : nil

    # Force Turbo Stream render for local button update even if phase completes
    if result.success?
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = result.phase_completed ? "ターン終了" : "準備完了状態を変更しました"
          render :create
        end
        format.html do
          flash[:notice] = result.phase_completed ? "ターン終了" : "準備完了状態を変更しました"
          redirect_to game_path(@game)
        end
      end
      return
    end

    handle_game_action(result, success_message: message)
  end
end
