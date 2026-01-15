require 'rails_helper'

RSpec.describe CardEffects::Steps::DealDamage, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user, san: 15) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user, san: 20, hp: 30) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :unit, key_code: "attacker", threshold_san: 10) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :board, position: :center)
  end

  let(:target_card) { create(:card, :unit, hp: 5) }
  let(:target_game_card) do
    create(:game_card, game: game, user: opponent_user, game_player: opponent,
           card: target_card, location: :board, position: :center, current_hp: 5)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: target_game_card,
      timing: :on_play
    )
  end

  describe '#call' do
    context '単体ターゲットにダメージを与える場合' do
      let(:step) { described_class.new(amount: 3, target: :selected_target) }

      it 'ターゲットのHPが減少する' do
        expect { step.call(context) }.to change { target_game_card.reload.current_hp }.by(-3)
      end
    end

    context '敵全体にダメージを与える場合' do
      let!(:enemy_unit2) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: target_card, location: :board, position: :left, current_hp: 5)
      end

      let(:step) { described_class.new(amount: 2, target: :all_enemies) }

      it '全ての敵ユニットのHPが減少する' do
        step.call(context)
        expect(target_game_card.reload.current_hp).to eq 3
        expect(enemy_unit2.reload.current_hp).to eq 3
      end
    end

    context '狂気ボーナスがある場合' do
      let(:step) { described_class.new(amount: 2, target: :selected_target, insane_bonus: 1) }

      context '狂気状態でない場合' do
        it '基本ダメージのみ与える' do
          expect { step.call(context) }.to change { target_game_card.reload.current_hp }.by(-2)
        end
      end

      context '狂気状態の場合' do
        before { player.update!(san: 10) }

        it 'ボーナスダメージも与える' do
          expect { step.call(context) }.to change { target_game_card.reload.current_hp }.by(-3)
        end
      end
    end

    context 'プレイヤーにダメージを与える場合' do
      let(:context) do
        CardEffects::Context.new(
          source_card: game_card,
          target: opponent,
          timing: :on_play
        )
      end
      let(:step) { described_class.new(amount: 5, target: :selected_target) }

      it 'プレイヤーのHPが減少する' do
        expect { step.call(context) }.to change { opponent.reload.hp }.by(-5)
      end
    end
  end
end
