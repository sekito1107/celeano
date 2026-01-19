# frozen_string_literal: true

class Game::Card::BaseComponent < ApplicationComponent
      def initialize(card_entity:)
        @card_entity = card_entity
      end

      def name
        card_source.name
      end

      def cost
        card_source.cost
      end

      def image_name
        # Fallback/Demo mapping for art
        name_str = card_source.name || ""
        if spell?
          "art_ritual.png"
        elsif name_str.include?("ダゴン") || name_str.include?("深きもの")
          "art_dagon.png"
        elsif name_str.include?("信者")
          "art_cultist.png"
        elsif name_str.include?("ショゴス") || name_str.include?("ハイドラ") || name_str.include?("クトゥルフ")
          "art_shoggoth.png"
        else
          # Default fallback
          card_source.image_name || "art_cultist.png"
        end
      end

      def text
        card_source.description
      end

      def flavor_text
        card_source.flavor_text
      end

      def description_insane
        card_source.description_insane
      end

      def total_attack
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

      def max_hp
        card_source.hp
      end

      # Visual State Helpers
      def attack_buffed?
        return false unless game_card?
        card_source.attack.to_i < total_attack.to_i
      end

      def damaged?
        return false unless game_card?
        hp < max_hp
      end

      def poisoned?
        return false unless game_card?
        @card_entity.modifiers.any? { |m| m.poison? }
      end

      def stunned?
        return false unless game_card?
        @card_entity.stunned?
      end

      def haste?
        card_source.haste?
      end

      def guardian?
        card_source.guardian?
      end

      def unit?
        card_source.card_type == "unit"
      end

      def spell?
        card_source.card_type == "spell"
      end

      def resolving?
        game_card? && @card_entity.location_resolving?
      end

      def graveyard?
        game_card? && @card_entity.location_graveyard?
      end

      def banished?
        game_card? && @card_entity.location_banished?
      end

      def threshold
        card_source.threshold_san
      end

      def has_threshold?
        threshold.present? && threshold > 0
      end

      private

      def game_card?
        @card_entity.is_a?(GameCard)
      end

      def card_source
        game_card? ? @card_entity.card : @card_entity
      end
end
