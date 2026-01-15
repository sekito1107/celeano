require 'rails_helper'

RSpec.describe TriggerRoundEffects do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:game_player) { create(:game_player, game: game, user: user) }
  let(:card) { create(:card) }

  # ボード上のユニット
  let!(:board_unit) do
    create(:game_card,
      game: game,
      game_player: game_player,
      card: card,
      location: :board
    )
  end

  # 墓地のカード
  let!(:graveyard_card) do
    create(:game_card,
      game: game,
      game_player: game_player,
      card: card,
      location: :graveyard
    )
  end

  describe '#call' do
    context 'on_round_start (default)' do
      before do
        relation = double('relation')
        allow(game.game_cards).to receive(:includes).with(:card).and_return(relation)
        allow(relation).to receive(:where).with(location: :board).and_return(relation)
        allow(relation).to receive(:to_a).and_return([ board_unit ])
        allow(board_unit).to receive(:reload).and_return(board_unit)
      end

      it 'triggers effects for board units' do
        expect(board_unit).to receive(:trigger).with(:on_round_start)
        described_class.call(game: game)
      end

      it 'does not trigger effects for graveyard cards' do
        allow(board_unit).to receive(:trigger)
        # board_unit のみが返されるため、graveyard_card は呼ばれない

        described_class.call(game: game, timing: :on_round_start)

        # board_unit が正しく呼ばれたことを確認
        expect(board_unit).to have_received(:trigger).with(:on_round_start)
      end
    end

    context 'on_round_end' do
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

      it 'triggers effects for board and graveyard cards' do
        expect(board_unit).to receive(:trigger).with(:on_round_end)
        expect(graveyard_card).to receive(:trigger).with(:on_graveyard)

        described_class.call(game: game, timing: :on_round_end)
      end
    end

    context 'イテレーション中にカードが破壊される場合' do
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
        # card_aのtriggerがcard_bを破壊するシナリオ
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

        described_class.call(game: game, timing: :on_round_start)
      end
    end
  end
end
