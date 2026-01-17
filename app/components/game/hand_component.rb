# frozen_string_literal: true

class Game::HandComponent < ApplicationComponent
  def initialize(game_player:, viewer:)
    @game_player = game_player
    @viewer = viewer
  end

  def cards
    @game_player.hand
  end

  def viewer_is_owner?
    @viewer == @game_player.user
  end

  def opponent_hand_count
    cards.count
  end
end
