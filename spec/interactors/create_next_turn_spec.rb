require 'rails_helper'

RSpec.describe CreateNextTurn, type: :interactor do
  let(:game) { create(:game, status: :playing) }
  let!(:current_turn) { create(:turn, game: game, turn_number: 1, status: :resolving) }

  describe '#call' do
    context 'ゲームが続いている場合' do
      it '次のターンが作成されること' do
        result = described_class.call(game: game, turn: current_turn)

        expect(result.next_turn).to be_present
        expect(result.next_turn.turn_number).to eq 2
        expect(result.next_turn.status).to eq 'planning'
      end

      it '現在のターンがdoneになること' do
        described_class.call(game: game, turn: current_turn)

        expect(current_turn.reload.status).to eq 'done'
      end
    end

    context 'ゲームが終了している場合' do
      before do
        game.update!(status: :finished)
      end

      it '次のターンが作成されないこと' do
        result = described_class.call(game: game, turn: current_turn)

        expect(result.next_turn).to be_nil
      end

      it '現在のターンのステータスが変わらないこと' do
        described_class.call(game: game, turn: current_turn)

        expect(current_turn.reload.status).to eq 'resolving'
      end
    end
  end
end
