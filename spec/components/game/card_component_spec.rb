# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::CardComponent, type: :component do
  let(:card) { create(:card, name: "Test Card", cost: 3, attack: 2, hp: 4, card_type: :unit) }

  context "with a static Card object" do
    it "renders correctly as a preview (default simple)" do
      render_inline(described_class.new(card_entity: card))

      expect(page).to have_css(".card-wrapper")
      # Default is :hand (simple)
      expect(page).to have_css(".simple-frame")
      expect(page).to have_css(".name-text", text: "Test Card")
      expect(page).to have_css(".simple-cost-circle", text: "3")
      expect(page).to have_css(".stat-group.attack-group .stat-value", text: "2")
      expect(page).to have_css(".stat-group.hp-group .stat-value", text: "4")
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

    describe "Visual States and Variants" do
      context "with :hand variant (Simple View)" do
        it "renders simple art and overlay" do
          render_inline(described_class.new(card_entity: game_card, variant: :hand))
          expect(page).to have_css(".card-simple")
          expect(page).to have_css(".simple-frame")
          expect(page).to have_css(".name-text", text: "Test Card")
          # Should NOT have the complex logic or detail panel
          expect(page).not_to have_css(".detail-panel")
        end
      end

      context "with :detail variant (Detailed View)" do
        it "renders integrated frame and full stats" do
          render_inline(described_class.new(card_entity: game_card, variant: :detail))
          expect(page).to have_css(".detail-panel") # Detail View Container
          expect(page).to have_css(".detail-header")
          expect(page).to have_css(".detail-name", text: "Test Card")
          # Should NOT have simple view classes logic that might conflict or duplicate
          expect(page).not_to have_css(".simple-frame")
        end
      end
  end
  end
end
