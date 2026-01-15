require 'rails_helper'

RSpec.describe TriggerRoundEndEffects do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:game_player) { create(:game_player, game: game, user: user) }
  let(:card) { create(:card) }

  let!(:board_unit) do
    create(:game_card,
      game: game,
      game_player: game_player,
      card: card,
      location: :board
    )
  end

  let!(:graveyard_card) do
    create(:game_card,
      game: game,
      game_player: game_player,
      card: card,
      location: :graveyard
    )
  end

  describe '#call' do
    before do
      relation = double('relation')
      allow(game.game_cards).to receive(:includes).with(:card).and_return(relation)

      board_relation = double('board_relation')
      graveyard_relation = double('graveyard_relation')

      allow(relation).to receive(:where).with(location: :board).and_return(board_relation)
      allow(relation).to receive(:where).with(location: :graveyard).and_return(graveyard_relation)

      allow(board_relation).to receive(:to_a).and_return([ board_unit ])
      allow(graveyard_relation).to receive(:to_a).and_return([ graveyard_card ])

      allow(board_unit).to receive(:reload).and_return(board_unit)
      allow(graveyard_card).to receive(:reload).and_return(graveyard_card)
    end

    it 'ボード上のユニットに対してon_round_endが呼ばれること' do
      expect(board_unit).to receive(:trigger).with(:on_round_end)
      allow(graveyard_card).to receive(:trigger)

      described_class.call(game: game)
    end

    it '墓地のカードに対してon_graveyardが呼ばれること' do
      allow(board_unit).to receive(:trigger)
      expect(graveyard_card).to receive(:trigger).with(:on_graveyard)

      described_class.call(game: game)
    end

    it 'ボード上の効果と墓地の効果の両方が呼ばれること' do
      expect(board_unit).to receive(:trigger).with(:on_round_end)
      expect(graveyard_card).to receive(:trigger).with(:on_graveyard)

      described_class.call(game: game)
    end
  end

  describe 'イテレーション中にカードが墓地に移動する場合' do
    let!(:card_a) do
      create(:game_card,
        game: game,
        game_player: game_player,
        card: card,
        location: :board
      )
    end

    let!(:card_b) do
      create(:game_card,
        game: game,
        game_player: game_player,
        card: card,
        location: :board
      )
    end

    before do
      allow(card_a).to receive(:trigger) do
        card_b.discard!
      end
      allow(card_a).to receive(:reload).and_return(card_a)

      relation = double('relation')
      allow(game.game_cards).to receive(:includes).with(:card).and_return(relation)
      allow(relation).to receive(:where).with(location: :board).and_return(relation)
      allow(relation).to receive(:where).with(location: :graveyard).and_return(double(to_a: []))
      allow(relation).to receive(:to_a).and_return([ card_a, card_b ])
    end

    it '破壊されたカードに対してon_round_endを呼ばない' do
      expect(card_b).to receive(:reload).and_call_original
      expect(card_b).not_to receive(:trigger)

      described_class.call(game: game)
    end
  end
end
