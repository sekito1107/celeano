# frozen_string_literal: true

class Game::HandComponent < ApplicationComponent
  def initialize(game_player:, viewer:)
    @game_player = game_player
    @viewer = viewer
  end

  def cards
    @cards ||= @game_player.hand
  end

  def viewer_is_owner?
    @viewer == @game_player.user
  end

  def render?
    @game_player.present?
  end
end
