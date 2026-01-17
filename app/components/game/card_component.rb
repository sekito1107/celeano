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

    kwargs = { card_entity: @card_entity }
    kwargs[:variant] = @variant if component_class == Game::Card::SimpleComponent
    render component_class.new(**kwargs)
  end
end
