require 'rails_helper'

RSpec.describe CardEffects::Steps::DoubleAttack, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :unit, attack: "3") }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :board, position: :center, current_attack: "3")
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: nil,
      timing: :on_attack
    )
  end

  describe '#call' do
    let(:step) { described_class.new }

    it '攻撃力が2倍になる' do
      expect { step.call(context) }.to change { game_card.reload.current_attack.to_i }.from(3).to(6)
    end

    context '攻撃力が既に高い場合' do
      before { game_card.update!(current_attack: "5") }

      it '2倍になる' do
        expect { step.call(context) }.to change { game_card.reload.current_attack.to_i }.from(5).to(10)
      end
    end

    context '攻撃力が0の場合' do
      before { game_card.update!(current_attack: "0") }

      it '0のまま変わらない' do
        expect { step.call(context) }.not_to change { game_card.reload.current_attack.to_i }.from(0)
      end
    end

    context '攻撃力がダイス記法の場合' do
      context '基本的なダイス記法' do
        before { game_card.update!(current_attack: "1d6") }

        it 'ダイス数が2倍になる' do
          step.call(context)
          expect(game_card.reload.current_attack).to eq "2d6"
        end
      end

      context '複数のダイスを持つ場合' do
        before { game_card.update!(current_attack: "2d6") }

        it 'ダイス数が2倍になる' do
          step.call(context)
          expect(game_card.reload.current_attack).to eq "4d6"
        end
      end

      context '補正値がある場合' do
        before { game_card.update!(current_attack: "1d6+2") }

        it 'ダイス数と補正値が両方2倍になる' do
          step.call(context)
          expect(game_card.reload.current_attack).to eq "2d6+4"
        end
      end

      context 'マイナス補正値がある場合' do
        before { game_card.update!(current_attack: "2d6-1") }

        it 'ダイス数と補正値が両方2倍になる' do
          step.call(context)
          expect(game_card.reload.current_attack).to eq "4d6-2"
        end
      end
    end

    context 'ターゲットがGameCardでない場合' do
      let(:context) do
        CardEffects::Context.new(
          source_card: game_card,
          target: player,
          timing: :on_attack
        )
      end
      let(:step) { described_class.new(target: :selected_target) }

      it '何も行わない' do
        expect { step.call(context) }.not_to change { game_card.reload.current_attack }
      end
    end

    context '無効な攻撃力記法の場合' do
      before { game_card.update!(current_attack: "invalid") }

      it 'NoMethodErrorを発生させる' do
        expect { step.call(context) }.to raise_error(NoMethodError)
      end
    end
  end
end
