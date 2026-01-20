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

  def recently_drawn?(game_card)
    # Check if the card was updated (moved to hand) within the last 10 seconds
    # Using created_at might be safer if draws create new records, but likely they are moved.
    # Assuming 'updated_at' changes when location changes.
    game_card.updated_at > 10.seconds.ago
  end
end
