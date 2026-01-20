# frozen_string_literal: true

class Game::GameOverOverlayComponentPreview < ViewComponent::Preview
  # @label Victory
  def victory
    render(Game::GameOverOverlayComponent.new(result: :win))
  end

  # @label Defeat (Standard - HP/Deck)
  def standard_defeat
    render(Game::GameOverOverlayComponent.new(result: :loss, reason: :hp))
  end

  # @label Defeat (Deck)
  def defeat_deck
    render(Game::GameOverOverlayComponent.new(result: :loss, reason: :deck))
  end

  # @label Sanity Death (Special)
  def sanity_death
    render(Game::GameOverOverlayComponent.new(result: :loss, reason: :san))
  end

  # @label Draw
  def draw
    render(Game::GameOverOverlayComponent.new(result: :draw))
  end

  # @label Draw (Mutual Insanity)
  def mutual_insanity
    render(Game::GameOverOverlayComponent.new(result: :draw, reason: :san))
  end
end
