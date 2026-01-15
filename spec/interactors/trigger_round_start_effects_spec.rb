require 'rails_helper'

RSpec.describe TriggerRoundStartEffects do
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
      allow(relation).to receive(:where).with(location: :board).and_return(relation)
      allow(relation).to receive(:to_a).and_return([ board_unit ])
      allow(board_unit).to receive(:reload).and_return(board_unit)
    end

    it 'ボード上のユニットに対してon_round_startが呼ばれること' do
      expect(board_unit).to receive(:trigger).with(:on_round_start)
      described_class.call(game: game)
    end

    it '墓地のカードに対して効果が呼ばれないこと' do
      allow(board_unit).to receive(:trigger)
      allow(graveyard_card).to receive(:trigger)

      described_class.call(game: game)

      expect(graveyard_card).not_to have_received(:trigger)
    end
  end

  describe 'イテレーション中にカードが破壊される場合' do
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
      allow(relation).to receive(:to_a).and_return([ card_a, card_b ])
    end

    it '破壊されたカードに対してtriggerを呼ばない' do
      expect(card_b).to receive(:reload).and_call_original
      expect(card_b).not_to receive(:trigger)

      described_class.call(game: game)
    end
  end
end
