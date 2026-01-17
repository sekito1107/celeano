# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Card::SimpleComponent, type: :component do
  let(:card) { create(:card, name: "Test Card", cost: 3, attack: 2, hp: 4, card_type: :unit) }

  context "with a static Card object" do
    it "renders correctly as a simple view" do
      render_inline(described_class.new(card_entity: card))

      expect(page).to have_css(".card-wrapper.card-simple")
      expect(page).to have_css(".simple-frame")
      expect(page).to have_css(".name-text", text: "Test Card")
      expect(page).to have_css(".simple-cost-circle", text: "3")
      expect(page).to have_css(".stat-value", text: "2")
      expect(page).to have_css(".stat-value", text: "4")

      # Should NOT have detail specific classes or orbs
      expect(page).not_to have_css(".detail-panel")
      expect(page).not_to have_css(".stat-orb")
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

    context "with :field variant" do
      it "adds field class" do
        render_inline(described_class.new(card_entity: game_card, variant: :field))
        expect(page).to have_css(".card-field")
        expect(page).to have_css(".card-simple")
      end
    end
  end
end
