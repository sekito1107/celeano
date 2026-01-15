require 'rails_helper'

RSpec.describe PayCost, type: :interactor do
  describe '.call' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }

    let!(:turn) { create(:turn, game: game) }

    let(:game_player) { create(:game_player, game: game, user: user, san: 10) }
    let!(:opponent) { create(:game_player, game: game) }

    let(:context_params) do
      {
        game: game,
        game_player: game_player,
        paid_cost: cost
      }
    end

    context '正常系: SAN値が足りている場合' do
      let(:cost) { 5 }

      it 'SAN値が減少し、成功する' do
        result = PayCost.call(context_params)

        expect(result).to be_a_success
        expect(game_player.reload.san).to eq 5
      end
    end

    context 'SAN値が尽きて発狂する場合' do
      let(:cost) { 15 }

      it '成功扱いになり、ゲーム終了処理が呼ばれる' do
        result = PayCost.call(context_params)

        # 成功扱い（context.fail!は呼ばれない）
        expect(result).to be_a_success
        expect(game_player.reload.san).to eq 0

        # ゲーム終了判定が行われる
        expect(game.reload).to be_finished
        expect(game.finish_reason).to eq 'SAN_DEATH'
      end
    end
  end
end
