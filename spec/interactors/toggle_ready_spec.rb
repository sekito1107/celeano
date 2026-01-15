require 'rails_helper'

RSpec.describe ToggleReady, type: :interactor do
  let(:game) { create(:game) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:player1) { create(:game_player, game: game, user: user1, ready: false) }
  let!(:player2) { create(:game_player, game: game, user: user2, ready: false) }
  let!(:turn) { create(:turn, game: game, turn_number: 1, status: :planning) }

  describe '#call' do
    context '1人目のプレイヤーが準備完了した場合' do
      it 'readyがtrueになること' do
        described_class.call(game_player: player1, turn: turn)

        expect(player1.reload.ready).to be true
      end

      it 'phase_completedがfalseであること' do
        result = described_class.call(game_player: player1, turn: turn)

        expect(result.phase_completed).to be false
      end

      it 'ターンステータスがplanningのままであること' do
        described_class.call(game_player: player1, turn: turn)

        expect(turn.reload.status).to eq 'planning'
      end
    end

    context '両プレイヤーが準備完了した場合' do
      let!(:player1) { create(:game_player, :with_deck, game: game, user: user1, ready: true) }
      let!(:player2) { create(:game_player, :with_deck, game: game, user: user2, ready: false) }

      it 'phase_completedがtrueであること' do
        result = described_class.call(game_player: player2, turn: turn)

        expect(result.phase_completed).to be true
      end

      it '両プレイヤーのreadyがリセットされること' do
        described_class.call(game_player: player2, turn: turn)

        expect(player1.reload.ready).to be false
        expect(player2.reload.ready).to be false
      end

      it '現在のターンがdoneになること' do
        described_class.call(game_player: player2, turn: turn)

        expect(turn.reload.status).to eq 'done'
      end

      it '次のターンが作成されること' do
        result = described_class.call(game_player: player2, turn: turn)

        expect(result.next_turn).to be_present
        expect(result.next_turn.turn_number).to eq 2
        expect(result.next_turn.status).to eq 'planning'
      end
    end

    context '準備完了を解除する場合' do
      before do
        player1.update!(ready: true)
      end

      it 'readyがfalseになること' do
        described_class.call(game_player: player1, turn: turn)

        expect(player1.reload.ready).to be false
      end
    end
  end
end
