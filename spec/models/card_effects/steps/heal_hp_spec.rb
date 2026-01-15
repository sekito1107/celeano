require 'rails_helper'

RSpec.describe CardEffects::Steps::HealHp, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :unit, hp: 5) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :board, position: :center, current_hp: 2)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: game_card,
      timing: :on_round_end
    )
  end

  describe '#call' do
    context '自分自身を回復する場合' do
      let(:step) { described_class.new(amount: 2, target: :self) }

      it 'HPが増加する' do
        expect { step.call(context) }.to change { game_card.reload.current_hp }.from(2).to(4)
      end
    end

    context '最大HPを超えないように回復する場合' do
      let(:step) { described_class.new(amount: 10, target: :self) }

      it '最大HPまでしか回復しない' do
        step.call(context)
        expect(game_card.reload.current_hp).to eq 5
      end
    end

    context '既に最大HPの場合' do
      before { game_card.update!(current_hp: 5) }
      let(:step) { described_class.new(amount: 3, target: :self) }

      it 'HPは変化しない' do
        expect { step.call(context) }.not_to change { game_card.reload.current_hp }
      end
    end

    context 'ターゲット制限(:selected_ally)がある場合' do
      let(:step) { described_class.new(amount: 3, target: :selected_ally) }

      context '味方ユニットを選択した場合' do
        it 'HPが増加する' do
          expect { step.call(context) }.to change { game_card.reload.current_hp }.from(2).to(5)
        end
      end

      context '敵ユニットを選択した場合' do
        let(:enemy_user) { create(:user) }
        let!(:enemy_player) { create(:game_player, game: game, user: enemy_user) }
        let(:enemy_card) do
          create(:game_card, game: game, user: enemy_user, game_player: enemy_player,
                 card: card, location: :board, position: :center, current_hp: 2)
        end
        let(:context) do
          CardEffects::Context.new(
            source_card: game_card,
            target: enemy_card,
            timing: :on_round_end
          )
        end

        it 'HPは変化しない' do
          expect { step.call(context) }.not_to change { enemy_card.reload.current_hp }
        end
      end
    end
  end
end
