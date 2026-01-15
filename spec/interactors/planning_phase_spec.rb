require 'rails_helper'

RSpec.describe PlanningPhase, type: :interactor do
  let(:game) { create(:game, status: :playing) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:player1) { create(:game_player, :with_deck, game: game, user: user1, ready: true) }
  let!(:player2) { create(:game_player, :with_deck, game: game, user: user2, ready: true) }
  let!(:turn) { create(:turn, game: game, turn_number: 1, status: :planning) }

  describe '#call' do
    context '正常系' do
      it '準備完了フラグがリセットされること' do
        described_class.call(game: game, turn: turn)

        expect(player1.reload.ready).to be false
        expect(player2.reload.ready).to be false
      end

      it 'ターンステータスがdoneになること' do
        described_class.call(game: game, turn: turn)

        expect(turn.reload.status).to eq 'done'
      end

      it '次のターンが作成されること' do
        result = described_class.call(game: game, turn: turn)

        expect(result.next_turn).to be_present
        expect(result.next_turn.turn_number).to eq 2
        expect(result.next_turn.status).to eq 'planning'
      end
    end

    context 'ResolvePhase中にゲームが終了した場合' do
      before do
        call_count = 0
        allow(game).to receive(:finished?) do
          call_count += 1
          call_count > 1
        end
      end

      it '次のターンが作成されないこと' do
        result = described_class.call(game: game, turn: turn)

        expect(result.next_turn).to be_nil
      end
    end
  end
end
