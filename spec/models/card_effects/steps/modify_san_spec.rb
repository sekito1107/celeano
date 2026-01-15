require 'rails_helper'

RSpec.describe CardEffects::Steps::ModifySan, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user, san: 20) }
  let!(:opponent) { create(:game_player, :guest, game: game, user: opponent_user, san: 20) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :spell) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :hand)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: nil,
      timing: :on_play
    )
  end

  describe '#call' do
    context '自分のSANを減少させる場合' do
      let(:step) { described_class.new(amount: -1) }

      it '自分のSANが減少する' do
        expect { step.call(context) }.to change { player.reload.san }.by(-1)
      end
    end

    context '敵プレイヤーのSANを減少させる場合' do
      let(:step) { described_class.new(amount: -2, target: :enemy_player) }

      it '敵のSANが減少する' do
        expect { step.call(context) }.to change { opponent.reload.san }.by(-2)
      end
    end

    context 'SANを増加させる場合' do
      let(:step) { described_class.new(amount: 3) }

      it 'SANが増加する' do
        expect { step.call(context) }.to change { player.reload.san }.by(3)
      end
    end

    context 'SAN減少により0未満になる場合' do
      before { player.update!(san: 1) }
      let(:step) { described_class.new(amount: -2) }

      it 'SANは0で止まる' do
        step.call(context)
        expect(player.reload.san).to eq 0
      end
    end
  end
end
