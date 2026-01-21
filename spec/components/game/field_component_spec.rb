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

  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  before do
    allow(game).to receive(:current_turn_number).and_return(1)
  end

  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  before do
    allow(game).to receive(:current_turn_number).and_return(1)
  end

  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  before do
    allow(game).to receive(:current_turn_number).and_return(1)
  end

  it "デッキ枚数が正しく表示されること" do
    render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))

    expect(page).to have_css(".field-deck-area .deck-count", text: "5")
  end

  context "ボードにカードがある場合" do
    let!(:left_card) { create(:game_card, :board, position: :left, game: game, game_player: game_player, user: user) }
    let!(:center_card) { create(:game_card, :board, position: :center, game: game, game_player: game_player, user: user) }

    before { game_player.reload }

    it "正しいスロットにカードが表示されること" do
      render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))

      expect(page).to have_css(".field-slot.left-slot .card-wrapper") # CardComponent renders a wrapper
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

  context "墓地にカードがある場合" do
    let!(:graveyard_card) { create(:game_card, :graveyard, game_player: game_player, game: game, user: user) }

    before { game_player.reload }

    it "墓地の一番上のカードが表示されること" do
      render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))

      expect(page).to have_css(".field-graveyard-area")
      expect(page).not_to have_css(".field-graveyard-area .empty-graveyard")
    end
  end

  context "墓地が空の場合" do
    it "墓地のプレースホルダーが表示されること" do
      render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))

      expect(page).to have_css(".field-graveyard-area .empty-graveyard")
    end
  end

  context "ユニット召喚数の表示" do
    let!(:turn) { create(:turn, game: game, turn_number: 1) }

    it "召喚数と上限が正しく表示されること" do
      render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))
      expect(page).to have_css(".unit-summon-info .value", text: "0 / 1")
    end

    context "ユニットを召喚している場合" do
      let(:unit_card) { create(:card, :unit) }
      let(:game_card) { create(:game_card, game: game, card: unit_card, user: user, game_player: game_player) }

      before do
        create(:move, turn: turn, user: user, game_card: game_card)
      end

      it "召喚数が更新されること" do
        render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))
        expect(page).to have_css(".unit-summon-info .value", text: "1 / 1")
      end
    end
  end

  context "召喚予定のユニットがある場合" do
    let!(:turn) { create(:turn, game: game, turn_number: 1) }
    let(:hand_card) { create(:game_card, :hand, game: game, user: user, game_player: game_player) }

    before do
       # Create a Move (schedule unit play)
       # Using 'center' directly as Move now has enum
       create(:move, turn: turn, user: user, game_card: hand_card, action_type: :play, position: :center)
    end

    context "自分が閲覧する場合" do
      before do
        # 実際の実装では、ProcessCardMovementによりlocationがresolvingになる
        hand_card.update!(location: :resolving)
      end

      it "スロットにカードが表示され、scheduled-summonクラスが付与されていること" do
        render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))

        expect(page).to have_css(".field-slot.center-slot .card-wrapper")
        expect(page).to have_css(".field-slot.center-slot .card-wrapper.scheduled-summon")
      end
    end

    context "相手が閲覧する場合" do
      let(:opponent) { create(:user) }
      let(:opponent_player) { create(:game_player, game: game, user: opponent) }

      it "スロットは空として表示されること" do
        render_inline(described_class.new(game_player: game_player, viewer: opponent, current_turn: turn))

        expect(page).to have_css(".field-slot.center-slot .empty-slot")
        expect(page).not_to have_css(".field-slot.center-slot .card-wrapper")
      end
    end
  end

  context "コスト消費の表示" do
    let!(:turn) { create(:turn, game: game, turn_number: 1) }

    before do
      allow(game).to receive(:current_turn_number).and_return(1)
      cards = create_list(:card, 2, cost: "1")
      # Move 1: Cost 1
      gc1 = create(:game_card, game: game, game_player: game_player, user: user, card: cards[0])
      create(:move, turn: turn, user: user, game_card: gc1, cost: 1)
      # Move 2: Cost 1
      gc2 = create(:game_card, game: game, game_player: game_player, user: user, card: cards[1])
      create(:move, turn: turn, user: user, game_card: gc2, cost: 1)
    end

    context "自身が閲覧する場合" do
      it "合計消費コストが表示されること" do
        render_inline(described_class.new(game_player: game_player, viewer: user, current_turn: turn))
        expect(page).to have_css(".field-pending-cost", text: "2")
        expect(page).to have_css(".field-pending-cost .label", text: "SAN COST:")
      end
    end

    context "相手が閲覧する場合" do
      let(:opponent) { create(:user) }

      it "コスト消費は表示されないこと" do
        render_inline(described_class.new(game_player: game_player, viewer: opponent, current_turn: turn))
        expect(page).not_to have_css(".field-pending-cost")
      end
    end
  end
end
