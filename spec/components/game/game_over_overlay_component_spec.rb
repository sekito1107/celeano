# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::GameOverOverlayComponent, type: :component do
  context "when result is nil" do
    it "does not render" do
      render_inline(described_class.new(result: nil))
      expect(page).to have_no_css(".game-over-overlay")
    end
  end

  context "when result is win" do
    it "renders VICTORY" do
      render_inline(described_class.new(result: :win))
      expect(page).to have_css(".game-over-overlay.win")
      expect(page).to have_content("VICTORY")
      expect(page).to have_no_content("DESCENDED INTO MADNESS")
    end
  end

  context "when result is loss" do
    context "standard defeat" do
      it "renders DEFEAT" do
        render_inline(described_class.new(result: :loss, reason: :hp))
        expect(page).to have_css(".game-over-overlay.loss")
        expect(page).to have_content("DEFEAT")
        expect(page).to have_no_content("DESCENDED INTO MADNESS")
      end
    end

    context "sanity death" do
      it "renders SANITY DEATH effects" do
        render_inline(described_class.new(result: :loss, reason: :san))
        expect(page).to have_css(".game-over-overlay.sanity-death")
        expect(page).to have_css(".shatter-layer")
        expect(page).to have_content("DESCENDED INTO MADNESS")
        expect(page).to have_css(".btn-insane")
      end
    end
  end

  context "when result is draw" do
    it "renders DRAW" do
      render_inline(described_class.new(result: :draw))
      expect(page).to have_css(".game-over-overlay.draw")
      expect(page).to have_content("DRAW")
    end
  end
end
