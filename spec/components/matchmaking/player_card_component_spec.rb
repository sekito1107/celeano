require "rails_helper"

RSpec.describe Matchmaking::PlayerCardComponent, type: :component do
  context "ユーザーカードを表示する場合" do
    let(:component) do
      described_class.new(
        name: "TestUser",
        title: "SEEKER",
        status: :ready,
        type: :user,
        image_path: "lobby/default_avatar.jpg"
      )
    end

    it "ユーザー情報が正しく表示されること" do
      render_inline(component)

      expect(page).to have_selector(".player-card.player-card--user")
      expect(page).to have_selector("img.player-card__image")
      expect(page).to have_content("TestUser")
      expect(page).to have_content("SEEKER")
      expect(page).to have_selector(".player-card__status--ready")
      expect(page).to have_content("Ready")
    end
  end

  context "対戦相手（UNKNOWN）カードを表示する場合" do
    let(:component) do
      described_class.new(
        name: "UNKNOWN",
        title: "CULTIST",
        status: :connecting,
        type: :enemy
      )
    end

    it "UNKNOWNアバターと情報が表示されること" do
      render_inline(component)

      expect(page).to have_selector(".player-card.player-card--enemy")
      expect(page).to have_selector(".player-card__unknown-avatar")
      expect(page).not_to have_selector("img.player-card__image")
      expect(page).to have_content("UNKNOWN")
      expect(page).to have_content("CULTIST")
      expect(page).to have_selector(".player-card__status--connecting")
      expect(page).to have_content("Connecting")
    end
  end
end
