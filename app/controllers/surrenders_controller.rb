class SurrendersController < ApplicationController
  include GameContextLoader
  include GameActionHelper

  def create
    if @game_player.surrender!
      result = GameActionResult.success(message: "降伏しました。")
    else
      result = GameActionResult.success(message: "ゲームは既に終了しています。")
    end
    handle_game_action(result)
  end
end
