# frozen_string_literal: true

class Game::Card::SimpleComponent < Game::Card::BaseComponent
      def initialize(card_entity:, variant: :hand, **html_attributes)
        super(card_entity: card_entity)
        @variant = variant
        @html_attributes = html_attributes
      end

      def variant_field?
        @variant == :field || @variant == :list
      end

      def interactive?
        # Only allow pinning/interaction if card is in hand, board, or list (modal)
        return false unless game_card?

        @card_entity.location_hand? || @card_entity.location_board? || @variant == :list
      end

      def detail_html
        render(Game::Card::DetailComponent.new(card_entity: @card_entity)).to_str
      end

      def card_hover_id
        @card_entity&.id || "preview"
      end

      def scheduled?
        # FieldComponent passes variant: :field for scheduled cards too,
        # but their location is still :hand or :resolving (reserved).
        # We check if it is displayed as :field but not actually on board location.
        return false unless game_card?

        variant_field? && (@card_entity.location_hand? || @card_entity.location_resolving?)
      end

      def wrapper_classes
        classes = [ "card-wrapper", "card-simple" ]
        classes << "card-field" if variant_field?
        classes << "card-graveyard" if graveyard?
        classes << "card-banished" if banished?
        classes << "state-stunned" if stunned?
        classes << "state-poisoned" if poisoned?
        classes << "scheduled-summon" if scheduled?
        classes.join(" ")
      end
end
