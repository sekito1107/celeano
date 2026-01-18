# frozen_string_literal: true

class Game::CardComponent < ApplicationComponent
  def initialize(card_entity:, variant: :hand)
    @card_entity = card_entity
    @variant = variant
  end

  def call
    component_class = case @variant
    when :hand, :field, :list, :resolving
      Game::Card::SimpleComponent
    when :detail
      Game::Card::DetailComponent
    else
      # Default to simple if unknown
      Game::Card::SimpleComponent
    end

    kwargs = { card_entity: @card_entity }
    # Stimulus attributes
    # Only generate detail HTML if we are NOT in detail view to avoid recursion/double rendering
    detail_html = (@variant == :detail) ? "" : render(Game::Card::DetailComponent.new(card_entity: @card_entity))

    kwargs[:data] = {
      controller: "game--card",
      game__card_id_value: @card_entity.id,
      game__card_type_value: @card_entity.card&.card_type, # unit or spell
      game__card_detail_html_value: detail_html,
      game__card_selected_value: false,
      game__board_target: "card",
      action: "click->game--card#click mouseenter->game--card#mouseenter mouseleave->game--card#mouseleave dragstart->game--card#dragstart dragend->game--card#dragend",
      draggable: "true"
    }

    # Field/Board cards are valid targets for spells
    if @variant == :field
      current_actions = kwargs[:data][:action]
      # Prioritize playCard (Spell targeting) over selection (CardController)
      # By prepending, playCard runs first. If it succeeds, the page reloads.
      # If not (e.g. no spell selected), execution bubbles/continues to selection.
      kwargs[:data][:action] = "dragover->game--board#dragover drop->game--board#drop click->game--board#playCard " + current_actions
    end

    kwargs[:variant] = @variant if component_class == Game::Card::SimpleComponent
    render component_class.new(**kwargs)
  end
end
