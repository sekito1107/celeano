# frozen_string_literal: true

class Game::GameOverOverlayComponent < ApplicationComponent
  def initialize(result: nil, reason: nil, game: nil, current_user: nil)
    if game && current_user
      @result = determine_result(game, current_user)
      @reason = determine_reason(game)
    else
      @result = result&.to_sym
      @reason = reason&.to_sym
    end
  end

  def render?
    @result.present?
  end

  def title
    case @result
    when :win
      "VICTORY"
    when :loss
      "DEFEAT"
    when :draw
      "DRAW"
    end
  end

  def sanity_death?
    @result == :loss && @reason == :san
  end

  def mutual_insanity?
    @result == :draw && @reason == :san
  end

  def container_classes
    classes = [ "game-over-overlay" ]
    if mutual_insanity?
      classes << "mutual-insanity"
    elsif sanity_death?
      classes << "sanity-death"
    else
      classes << @result.to_s
    end
    classes.join(" ")
  end

  private

  def determine_result(game, user)
    return nil unless game.finished?
    return :win if game.winner_id == user.id
    return :loss if game.loser_id == user.id
    :draw
  end

  def determine_reason(game)
    case game.finish_reason
    when "SAN_DEATH" then :san
    when "HP_DEATH" then :hp
    when "DECK_DEATH" then :deck
    when "SAN_DRAW" then :san
    when "HP_DRAW" then :hp
    else :other
    end
  end
end
