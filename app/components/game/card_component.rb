# frozen_string_literal: true

class Game::CardComponent < ApplicationComponent
  def initialize(card_entity:, variant: :hand)
    @card_entity = card_entity
    @variant = variant
  end

  def call
    component_class = case @variant
    when :hand, :field
      Game::Card::SimpleComponent
    when :detail
      Game::Card::DetailComponent
    else
      # Default to simple if unknown
      Game::Card::SimpleComponent
    end

    render component_class.new(card_entity: @card_entity, variant: @variant)
  end
end
