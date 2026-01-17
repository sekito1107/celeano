# frozen_string_literal: true

class Game::StatusBarComponent < ApplicationComponent
  def initialize(game_player:)
    @game_player = game_player
  end

  def hp
    @game_player.hp
  end

  def max_hp
    GamePlayer::DEFAULT_HP
  end

  def hp_percent
    (hp.to_f / max_hp * 100).clamp(0, 100)
  end

  def san
    @game_player.san
  end

  def max_san
    # SANに上限はないため、現在の値がデフォルトを超えている場合は現在の値を分母とする（バーが100%になる）
    [@game_player.san, GamePlayer::DEFAULT_SAN].max
  end

  def san_percent
    (san.to_f / max_san * 100).clamp(0, 100)
  end

  def insane?
    @game_player.insane?
  end
end
