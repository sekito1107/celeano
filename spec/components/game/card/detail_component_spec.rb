# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Card::DetailComponent, type: :component do
  let(:card) { create(:card, name: "Detail Card", cost: 5, attack: 6, hp: 7, card_type: :unit, description: "Some description") }

  it "renders correctly as a detail view" do
    render_inline(described_class.new(card_entity: card))

    expect(page).to have_css(".card-wrapper.card-detail")
    expect(page).to have_css(".detail-panel")
    expect(page).to have_css(".detail-name", text: "Detail Card")
    expect(page).to have_css(".detail-cost", text: "5")
    expect(page).to have_css(".stat-atk .value", text: "6")
    expect(page).to have_css(".stat-hp .value", text: "7")
    expect(page).to have_css(".detail-description-box", text: "Some description")

    # Should NOT have simple view classes
    expect(page).not_to have_css(".card-simple")
    expect(page).not_to have_css(".simple-frame")
  end
end
