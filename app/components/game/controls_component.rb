# frozen_string_literal: true

class Game::ControlsComponent < ApplicationComponent
  def initialize(game_player:)
    @game_player = game_player
  end

  private

  def ready_label
    @game_player.ready ? "Waiting for opponent" : "Confirm ready state"
  end

  def ready_text
    @game_player.ready ? "WAIT" : "READY"
  end

  def disabled?
    @game_player.ready
  end
end
