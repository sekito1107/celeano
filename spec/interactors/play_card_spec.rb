require 'rails_helper'

RSpec.describe PlayCard, type: :interactor do
  describe '.organized' do
    it 'Interactorが期待通りの順序で並んでいること' do
      expect(described_class.organized).to eq([
        ValidatePlay,
        PayCost,
        CreateMove,
        ProcessCardMovement,
        TriggerPlayEffect
      ])
    end
  end

  describe '.call' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }
    let(:game_player) { create(:game_player, game: game, user: user, san: 20) }
    let!(:turn) { create(:turn, game: game, status: :planning) }

    let(:card) { create(:card, :unit, cost: "1") }
    let(:game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: card, location: :hand) }

    let(:params) do
      {
        game: game,
        turn: turn,
        game_player: game_player,
        game_card: game_card,
        position: 'center'
      }
    end

    context '全ての条件を満たして正常にプレイする場合' do
      it '成功し、コストが引かれ、カードが予約状態に移動すること' do
        result = PlayCard.call(params)

        expect(result).to be_a_success

        expect(game_player.reload.san).to eq 19

        expect(Move.count).to eq 1

        # Planningフェーズではresolvingに移動（解決フェーズでboardに移動）
        game_card.reload
        expect(game_card.location).to eq 'resolving'
        expect(game_card.position).to eq 'center'
      end
    end

    context 'バリデーション(ValidatePlay)で失敗する場合' do
      before { turn.update!(status: :resolving) }

      it '失敗し、状態が変化していないこと' do
        result = PlayCard.call(params)

        expect(result).to be_a_failure
        expect(game_player.reload.san).to eq 20
        expect(game_card.reload.location).to eq 'hand'
        expect(Move.count).to eq 0
      end
    end
  end
end
