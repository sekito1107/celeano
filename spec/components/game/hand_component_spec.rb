# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::HandComponent, type: :component do
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let(:game) { create(:game) }
  let!(:game_player) { create(:game_player, game: game, user: user) }
  let!(:opponent_game_player) { create(:game_player, game: game, user: opponent_user) }

  before do
    # 手札にカードを作成
    create_list(:game_card, 3, :hand, game: game, game_player: game_player, user: user)
  end

  context "when viewer is the owner" do
    it "renders the cards face up" do
      render_inline(described_class.new(game_player: game_player, viewer: user))

      expect(page).to have_css(".hand-container")
      expect(page).to have_css(".hand-card-wrapper", count: 3)
      expect(page).not_to have_css(".card-back")
    end
  end

  context "when viewer is the opponent" do
    it "renders the cards face down" do
      render_inline(described_class.new(game_player: game_player, viewer: opponent_user))

      expect(page).to have_css(".hand-container")
      expect(page).to have_css(".hand-card-wrapper.opponent-card", count: 3)
      expect(page).to have_css(".card-back", count: 3)
    end
  end
end
