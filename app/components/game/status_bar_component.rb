# frozen_string_literal: true

class Game::StatusBarComponent < ApplicationComponent
  def initialize(game_player:)
    @game_player = game_player
  end

  def hp
    @game_player.hp
  end

  def max_hp
    GamePlayer::MAX_HP
  end

  def hp_percent
    (hp.to_f / max_hp * 100).clamp(0, 100)
  end

  def san
    @game_player.san
  end

  def max_san
    GamePlayer::MAX_SAN
  end

  def san_percent
    (san.to_f / max_san * 100).clamp(0, 100)
  end

  def insane?
    @game_player.insane?
  end
end
