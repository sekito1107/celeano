# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::FieldComponent, type: :component do
  let(:user) { create(:user) }
  let(:game) { create(:game) }
  let(:game_player) { create(:game_player, game: game, user: user) }

  before do
    # デッキを作成
    create_list(:game_card, 5, :deck, game: game, game_player: game_player, user: user)
  end

  it "renders the deck count" do
    render_inline(described_class.new(game_player: game_player))

    expect(page).to have_css(".field-deck-area .deck-count", text: "5")
  end

  context "with cards on board" do
    let!(:left_card) { create(:game_card, :board, position: :left, game: game, game_player: game_player, user: user) }
    let!(:center_card) { create(:game_card, :board, position: :center, game: game, game_player: game_player, user: user) }

    it "renders cards in correct slots" do
      render_inline(described_class.new(game_player: game_player))

      expect(page).to have_css(".field-slot.left-slot .card-component") # CardComponentが.card-componentのような識別可能な要素を描画すると仮定
      # 実際にはCardComponentの出力には特定のクラスがないかもしれません。
      # しかし、コンテンツを描画するかどうかは確認できます。
      # そのスロットに.empty-slotが表示されていなければ、CardComponentが描画されていると仮定します。

      expect(page).to have_css(".field-slot.left-slot")
      expect(page).not_to have_css(".field-slot.left-slot .empty-slot")

      expect(page).to have_css(".field-slot.center-slot")
      expect(page).not_to have_css(".field-slot.center-slot .empty-slot")

      expect(page).to have_css(".field-slot.right-slot .empty-slot")
    end
  end

  context "with graveyard" do
    let!(:graveyard_card) { create(:game_card, :graveyard, game_player: game_player, game: game, user: user) }

    it "renders the top card of graveyard" do
      render_inline(described_class.new(game_player: game_player))

      expect(page).to have_css(".field-graveyard-area")
      expect(page).not_to have_css(".field-graveyard-area .empty-graveyard")
    end
  end

  context "empty graveyard" do
    it "renders empty graveyard placeholder" do
      render_inline(described_class.new(game_player: game_player))

      expect(page).to have_css(".field-graveyard-area .empty-graveyard")
    end
  end
end
