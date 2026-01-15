require 'rails_helper'

RSpec.describe ShuffleDeck, type: :interactor do
  let(:game) { create(:game, seed: 12345) }
  let(:user) { create(:user) }
  let(:player) { create(:game_player, game: game, user: user) }
  let(:cards) { create_list(:card, 10) }

  before do
    # デッキにカードを追加（10枚でシャッフル後に初期順序と一致する確率を極小化）
    cards.each_with_index do |card, index|
      create(:game_card, game: game, game_player: player, card: card, location: :deck, position_in_stack: index)
    end
  end

  describe '#call' do
    subject(:context) { described_class.call(game: game) }

    it 'succeeds' do
      expect(context).to be_a_success
    end

    it 'shuffles the deck and maintains valid positions' do
      initial_order = player.deck.pluck(:card_id)

      described_class.call(game: game)

      shuffled_order = player.reload.deck.pluck(:card_id)

      expect(shuffled_order).not_to eq(initial_order)

      positions = player.deck.pluck(:position_in_stack).sort
      expect(positions).to eq((0..9).to_a)
    end

    it 'uses game seed for deterministic shuffling' do
      expected_seed = game.seed + player.id
      deck_cards = player.deck.to_a

      # 同じシードで期待される順序を計算
      expected_order = deck_cards.shuffle(random: Random.new(expected_seed)).map(&:id)

      described_class.call(game: game)

      actual_order = player.reload.deck.order(:position_in_stack).pluck(:id)

      expect(actual_order).to eq(expected_order)
    end
  end
end
