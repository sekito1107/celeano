# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::CardComponent, type: :component do
  let(:card) { create(:card, name: "Test Card", cost: 3, attack: 2, hp: 4, card_type: :unit) }

  context "with a static Card object" do
    it "renders correctly as a preview" do
      render_inline(described_class.new(card_entity: card))

      expect(page).to have_css(".card-wrapper")
      expect(page).to have_css(".card-frame")
      expect(page).to have_css(".card-name", text: "Test Card")
      expect(page).to have_css(".cost-orb", text: "3")
      expect(page).to have_css(".attack-orb", text: "2")
      expect(page).to have_css(".hp-orb", text: "4")
    end
  end

  context "with a dynamic GameCard object" do
    let(:user) { create(:user) }
    let(:game) { create(:game) }
    let(:game_player) { create(:game_player, user: user, game: game) }
    let(:game_card) do
      create(:game_card,
        card: card,
        user: user,
        game: game,
        game_player: game_player,
        current_hp: 4
      )
    end

    describe "Visual States" do
      it "renders unit frame for units" do
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".frame-unit")
        expect(page).not_to have_css(".frame-spell")
      end

      it "renders spell frame for spells" do
        card.update(card_type: :spell)
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".frame-spell")
        expect(page).not_to have_css(".frame-unit")
      end

      it "shows buffed text color when attack is increased" do
        # attack 2 -> 3
        allow(game_card).to receive(:total_attack).and_return(3)
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".attack-orb.text-buffed", text: "3")
      end

      it "shows damaged text color when hp is decreased" do
        # hp 4 -> 3
        game_card.update(current_hp: 3)
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".hp-orb.text-damaged", text: "3")
      end

      it "shows poison effect overlay when poisoned" do
        create(:game_card_modifier, game_card: game_card, effect_type: :poison)
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".status-effect-overlay.effect-poison")
      end

      it "shows stunned state class when stunned" do
        create(:game_card_modifier, game_card: game_card, effect_type: :stun)
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".card-frame.state-stunned")
      end

      it "shows badges for keywords" do
        create(:card_keyword, card: card, keyword: create(:keyword, name: "haste"))
        render_inline(described_class.new(card_entity: game_card))
        expect(page).to have_css(".keyword-badge", text: "⚡")
      end
    end
  end
end
