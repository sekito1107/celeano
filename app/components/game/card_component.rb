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
    if @variant == :detail
      return render Game::Card::DetailComponent.new(card_entity: @card_entity)
    end

    detail_html = render(Game::Card::DetailComponent.new(card_entity: @card_entity))

    # Check if card is a pile top card (graveyard/banished) on the field
    # Use respond_to? for easier testing/duck typing
    is_pile_on_field = @variant == :field &&
                       ((@card_entity.respond_to?(:location_graveyard?) && @card_entity.location_graveyard?) ||
                        (@card_entity.respond_to?(:location_banished?) && @card_entity.location_banished?))

    base_actions = [
      "mouseenter->game--card#mouseenter",
      "mouseleave->game--card#mouseleave"
    ]

    # Determine if the card should be interactive (clickable, draggable)
    # Determine if the card should be interactive (clickable, draggable)
    # Resolving cards (Reserved Spells) should be clickable (for details) but not draggable
    is_clickable = !is_pile_on_field
    is_draggable = !is_pile_on_field && @variant != :resolving

    if is_clickable
      base_actions << "click->game--card#click"
    end

    if is_draggable
      base_actions << "dragstart->game--card#dragstart"
      base_actions << "dragend->game--card#dragend"
    end

    card_source = @card_entity.respond_to?(:card) ? @card_entity.card : @card_entity

    kwargs[:data] = {
      controller: "game--card",
      game__card_id_value: @card_entity.id,
      game__card_type_value: card_source&.card_type, # unit or spell
      game__card_detail_html_value: detail_html,
      game__card_selected_value: false,
      game__board_target: "card",
      action: base_actions.join(" ")
    }

    # Set draggable HTML attribute explicitly
    kwargs[:draggable] = is_draggable ? "true" : "false"

    # Field/Board cards are valid targets for spells
    if @variant == :field && !is_pile_on_field
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
