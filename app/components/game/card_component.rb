# frozen_string_literal: true

class Game::CardComponent < ApplicationComponent
  def initialize(card_entity:)
    @card_entity = card_entity
  end

  def name
    card_source.name
  end

  def cost
    card_source.cost
  end

  def attack
    if game_card?
      @card_entity.total_attack
    else
      card_source.attack
    end
  end

  def hp
    if game_card?
      @card_entity.current_hp
    else
      card_source.hp
    end
  end

  private

  def game_card?
    @card_entity.is_a?(GameCard)
  end

  def card_source
    game_card? ? @card_entity.card : @card_entity
  end
end
