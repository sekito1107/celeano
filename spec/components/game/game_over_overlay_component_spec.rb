# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::GameOverOverlayComponent, type: :component do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:player) { create(:game_player, user: user, game: game) }
  let(:opponent) { create(:game_player, user: other_user, game: game) }

  before do
    game.game_players << player
    game.game_players << opponent
    create(:turn, game: game, turn_number: 1)
  end

  context "when game is not finished" do
    it "does not render" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).not_to have_css(".game-over-overlay")
    end
  end

  context "when user wins" do
    before do
      game.finish_game!(opponent, "HP_DEATH")
    end

    it "renders victory screen" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.win")
      expect(page).to have_content("VICTORY")
    end
  end

  context "when user loses (HP Death)" do
    before do
      game.finish_game!(player, "HP_DEATH")
    end

    it "renders defeat screen" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.loss")
      expect(page).to have_content("DEFEAT")
    end
  end

  context "when user loses (Sanity Death)" do
    before do
      game.finish_game!(player, "SAN_DEATH")
    end

    it "renders sanity death screen" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.sanity-death")
      expect(page).to have_css(".shatter-text", text: "DESCENDED INTO MADNESS")
    end
  end

  context "when game is a DRAW (Mutual Insanity)" do
    before do
      game.finish_draw!("SAN_DRAW")
    end

    it "renders mutual insanity screen" do
      render_inline(described_class.new(game: game, current_user: user))

      expect(page).to have_css(".game-over-overlay.mutual-insanity")
      expect(page).to have_css(".shatter-container.mutual-insanity-mode")

      # Verifying text content (Draw + Mutual Insanity)
      expect(page).to have_css(".shatter-text", text: "DRAW")
      expect(page).to have_css(".shatter-subtitle", text: "MUTUAL INSANITY")
      expect(page).to have_css(".shatter-subsubtitle", text: "狂気への共振")
    end
  end
end
