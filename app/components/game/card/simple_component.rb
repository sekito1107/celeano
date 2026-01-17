# frozen_string_literal: true

class Game::Card::SimpleComponent < Game::Card::BaseComponent
      def initialize(card_entity:, variant: :hand)
        super(card_entity: card_entity)
        @variant = variant
      end

      def variant_field?
        @variant == :field
      end

      def interactive?
        # Only allow pinning/interaction if card is in hand or board
        return false unless game_card?

        @card_entity.location_hand? || @card_entity.location_board?
      end

      def detail_html
        render(Game::Card::DetailComponent.new(card_entity: @card_entity)).to_str
      end

      def card_hover_id
        @card_entity&.id || "preview"
      end

      def wrapper_classes
        classes = [ "card-wrapper", "card-simple" ]
        classes << "card-field" if variant_field?
        classes << "card-graveyard" if graveyard?
        classes.join(" ")
      end
end
