# frozen_string_literal: true

class Game::StatusBarComponent < ApplicationComponent
  def initialize(game_player:, controls: false)
    @game_player = game_player
    @controls = controls
  end

  def controls?
    @controls
  end

  def ready?
    !!@game_player.ready
  end

  def hp
    @game_player.hp
  end

  def max_hp
    @game_player.max_hp
  end

  def san
    @game_player.san
  end

  def max_san
    @game_player.max_san
  end

  def insane?
    @game_player.insane?
  end

  SANITY_CRITICAL_THRESHOLD = 5
  SANITY_LOW_THRESHOLD = 10
  SANITY_WARNING_THRESHOLD = 15
  def sanity_level_class
    case san
    when 0..SANITY_CRITICAL_THRESHOLD
      "sanity-critical"
    when (SANITY_CRITICAL_THRESHOLD + 1)..SANITY_LOW_THRESHOLD
      "sanity-low"
    when (SANITY_LOW_THRESHOLD + 1)..SANITY_WARNING_THRESHOLD
      "sanity-warning"
    else
      "sanity-normal"
    end
  end
end
