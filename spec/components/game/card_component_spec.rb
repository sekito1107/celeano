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

      context "Interaction Logic" do
        it "has click action by default (Board Slot)" do
          render_inline(described_class.new(card_entity: game_card, variant: :field))
          expect(page.find(".card-wrapper")["data-action"]).to include("click->game--card#click")
        end

        context "when in graveyard (Pile Top)" do
          before do
            # Mock location checks since state management might be complex in specs
            allow(game_card).to receive(:location_graveyard?).and_return(true)
            allow(game_card).to receive(:location_banished?).and_return(false)
          end

          it "does NOT have click action when variant is field (Pile View)" do
             render_inline(described_class.new(card_entity: game_card, variant: :field))
             action = page.find(".card-wrapper")["data-action"]
             expect(action).not_to include("click->game--card#click")
             expect(action).to include("mouseenter->game--card#mouseenter")
             expect(page.find(".card-wrapper")["draggable"]).to eq("false")
          end

          it "DOES have click action when variant is list (Modal View)" do
             render_inline(described_class.new(card_entity: game_card, variant: :list))
             expect(page.find(".card-wrapper")["data-action"]).to include("click->game--card#click")
          end
        end

        context "when resolving (Reserved Spell)" do
          it "does HAVE click action but NOT draggable capability" do
            render_inline(described_class.new(card_entity: game_card, variant: :resolving))
            element = page.find(".card-wrapper")
            action = element["data-action"]

            expect(action).to include("click->game--card#click")
            expect(action).not_to include("dragstart->game--card#dragstart")
            expect(element["draggable"]).to eq("false")
            # Should still have hover effects
            expect(action).to include("mouseenter->game--card#mouseenter")
          end
        end
      end
  end
  end
end
