require 'rails_helper'

RSpec.describe ProcessStatusEffects, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit) }

  describe '#call' do
    context '毒状態のユニットがいる場合' do
      let!(:poisoned_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 5)
        create(:game_card_modifier, game_card: card, value: 2)
        card
      end

      it '毒ダメージを受ける' do
        described_class.call(game: game, turn: turn)

        poisoned_unit.reload
        expect(poisoned_unit.current_hp).to eq 3
      end

      it 'poison_damageのBattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change { BattleLog.where(event_type: "poison_damage").count }.by(1)
      end
    end

    context '継続時間のあるmodifierがある場合' do
      let!(:stunned_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 5)
        create(:game_card_modifier, :stun, game_card: card, duration: 2)
        card
      end

      it '継続時間が1減少する' do
        described_class.call(game: game, turn: turn)

        stunned_unit.reload
        modifier = stunned_unit.modifiers.find_by(effect_type: :stun)
        expect(modifier.duration).to eq 1
      end
    end

    context '継続時間が1のmodifierがある場合' do
      let!(:unit_with_expiring_modifier) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 5)
        create(:game_card_modifier, :stun, game_card: card, duration: 1)
        card
      end

      it 'modifierが削除される' do
        described_class.call(game: game, turn: turn)

        expect(unit_with_expiring_modifier.reload.modifiers.count).to eq 0
      end

      it 'modifier_expiredのBattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change { BattleLog.where(event_type: "modifier_expired").count }.by(1)
      end
    end

    context '複数の毒状態がある場合' do
      let!(:multi_poisoned_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 10)
        create(:game_card_modifier, game_card: card, value: 2)
        create(:game_card_modifier, game_card: card, value: 3)
        card
      end

      it '合計毒ダメージ(5)を受ける' do
        described_class.call(game: game, turn: turn)

        multi_poisoned_unit.reload
        expect(multi_poisoned_unit.current_hp).to eq 5
      end
    end

    context '複数の異なるmodifier(poison + stun)がある場合' do
      let!(:multi_status_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 10)
        create(:game_card_modifier, game_card: card, value: 3) # poison
        create(:game_card_modifier, :stun, game_card: card, duration: 2)
        card
      end

      it '毒ダメージを受ける' do
        described_class.call(game: game, turn: turn)

        expect(multi_status_unit.reload.current_hp).to eq 7
      end

      it 'stunのdurationが減少する' do
        described_class.call(game: game, turn: turn)

        stun_modifier = multi_status_unit.reload.modifiers.find_by(effect_type: :stun)
        expect(stun_modifier.duration).to eq 1
      end
    end

    context '複数のduration付きmodifierが同時に期限切れになる場合' do
      let!(:multi_expiring_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 10)
        create(:game_card_modifier, :stun, game_card: card, duration: 1)
        create(:game_card_modifier, game_card: card, effect_type: :attack_buff, value: 2, duration: 1)
        card
      end

      it '両方のmodifierが削除される' do
        described_class.call(game: game, turn: turn)

        expect(multi_expiring_unit.reload.modifiers.count).to eq 0
      end

      it '2つのmodifier_expiredログが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change { BattleLog.where(event_type: "modifier_expired").count }.by(2)
      end
    end

    context 'ゲームが終了している場合' do
      let!(:poisoned_unit) do
        card = create(:game_card, game: game, user: user, game_player: player,
                      card: unit_card, location: :board, position: :center, current_hp: 5)
        create(:game_card_modifier, game_card: card, value: 2)
        card
      end

      before do
        game.update!(status: :finished)
      end

      it '毒ダメージを受けない' do
        described_class.call(game: game, turn: turn)

        poisoned_unit.reload
        expect(poisoned_unit.current_hp).to eq 5
      end
    end

    context '盤面にユニットがいない場合' do
      it 'エラーなく完了する' do
        expect {
          described_class.call(game: game, turn: turn)
        }.not_to raise_error
      end
    end
  end
end
