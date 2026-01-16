# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::CardComponent, type: :component do
  let(:card) { create(:card, name: "Test Card", cost: 3, attack: 2, hp: 4) }

  context "with a static Card object" do
    it "renders the card details correctly" do
      render_inline(described_class.new(card_entity: card))

      expect(page).to have_css(".card-component")
      expect(page).to have_css(".card-name", text: "Test Card")
      expect(page).to have_css(".card-cost", text: "3")
      expect(page).to have_css(".stat-attack", text: "2")
      expect(page).to have_css(".stat-hp", text: "4")
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
        current_hp: 1, # Damaged
        current_attack: 5 # Buffed
      )
    end

    # Explicitly mock total_attack since it might rely on modifiers/calculations
    # that are not fully set up in this isolated component test context,
    # although standard factory usage should be fine if logic is in model.
    # However, to be safe and clear about what we are testing (the component),
    # we rely on the model's behavior.
    
    it "renders the game card details with current stats" do
      # Ensure total_attack returns the expected value (logic is in model, but we check if component uses it)
      allow(game_card).to receive(:total_attack).and_return(5)

      render_inline(described_class.new(card_entity: game_card))

      expect(page).to have_css(".card-component")
      expect(page).to have_css(".card-name", text: "Test Card")
      expect(page).to have_css(".card-cost", text: "3")
      expect(page).to have_css(".stat-attack", text: "5")
      expect(page).to have_css(".stat-hp", text: "1")
    end
  end
end
