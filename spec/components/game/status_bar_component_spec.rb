# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::StatusBarComponent, type: :component do
  let(:user) { create(:user) }
  let(:game) { create(:game) }
  let(:game_player) { create(:game_player, game: game, user: user, hp: 20, san: 20) }

  before do
    # 定数が定義されていることを確認 (テスト内で定数に依存するため)
    stub_const("GamePlayer::DEFAULT_HP", 20)
    stub_const("GamePlayer::DEFAULT_SAN", 20)
  end

  context "通常状態の場合" do
    it "HPとSANが正しく表示されること" do
      render_inline(described_class.new(game_player: game_player))

      expect(page).to have_css(".status-bar-container")
      expect(page).to have_css(".hp-row .status-text", text: "20 / 20")
      expect(page).to have_css(".san-row .status-text", text: "20 / 20")
    end

    it "HPバーの幅が100%であること" do
      render_inline(described_class.new(game_player: game_player))
      expect(page).to have_css(".hp-fill[style*='width: 100.0%']")
    end
  end

  context "ダメージを受けている場合" do
    before { game_player.update(hp: 10, san: 5) }

    it "数値が正しく更新されていること" do
      render_inline(described_class.new(game_player: game_player))
      expect(page).to have_css(".hp-row .status-text", text: "10 / 20")
      expect(page).to have_css(".san-row .status-text", text: "5 / 20")
    end

    it "バーの幅が正しく計算されていること" do
      render_inline(described_class.new(game_player: game_player))
      # 10/20 = 50%
      expect(page).to have_css(".hp-fill[style*='width: 50.0%']")
      # 5/20 = 25%
      expect(page).to have_css(".san-fill[style*='width: 25.0%']")
    end
  end

  context "発狂状態の場合 (SAN <= 0)" do
    before { game_player.update(san: 0) }

    it "insaneクラスが付与されていること" do
      render_inline(described_class.new(game_player: game_player))
      expect(page).to have_css(".status-bar-container.insane")
    end
  end
end
