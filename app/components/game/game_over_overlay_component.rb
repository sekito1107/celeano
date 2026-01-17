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

  def container_classes
    classes = [ "game-over-overlay" ]
    classes << "sanity-death" if sanity_death?
    classes << @result.to_s unless sanity_death?
    classes.join(" ")
  end

  private

  def determine_result(game, user)
    return :win if game.winner_id == user.id
    return :loss if game.loser_id == user.id
    :draw
  end

  def determine_reason(game)
    case game.finish_reason
    when "SAN_DEATH" then :san
    when "HP_DEATH" then :hp
    when "DECK_DEATH" then :deck
    else :other
    end
  end
end
