require 'rails_helper'

RSpec.describe GamePlayer, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:player) { create(:game_player, game: game, user: user, hp: 10, san: 20) }

  let(:card_master) { create(:card, name: "テストカード", key_code: "test_c") }

  describe '#pay_cost!' do
    it 'SAN値が減少し、pay_costログが記録されること' do
      expect {
        player.pay_cost!(5)
      }.to change(BattleLog, :count).by(1)

      expect(player.reload.san).to eq 15

      log = BattleLog.last
      expect(log.event_type).to eq 'pay_cost'
      expect(log.details['amount']).to eq 5
      expect(log.details['current_san']).to eq 15
    end

    it '0未満にはならず、0で止まること' do
      player.pay_cost!(100)
      expect(player.reload.san).to eq 0
    end

    it 'ゲーム終了判定は呼び出し元で行う（モデルでは行わない）' do
      player.pay_cost!(20) # SAN 20 -> 0

      # モデルは状態変更のみ、ゲーム終了判定は行わない
      expect(player.reload.san).to eq 0
      expect(game.reload).not_to be_finished
    end
  end

  describe '#take_damage!' do
    it 'HPが減少し、take_damageログが記録されること' do
      expect {
        player.take_damage!(3)
      }.to change(BattleLog, :count).by(1)

      expect(player.reload.hp).to eq 7

      log = BattleLog.last
      expect(log.event_type).to eq 'take_damage'
      expect(log.details['current_hp']).to eq 7
      expect(log.details['amount']).to eq 3
    end

    it '0未満にはならず、0で止まること' do
      player.take_damage!(100)
      expect(player.reload.hp).to eq 0
    end

    it 'ゲーム終了判定は呼び出し元で行う（モデルでは行わない）' do
      player.take_damage!(100)

      # モデルは状態変更のみ、ゲーム終了判定は行わない
      expect(player.reload.hp).to eq 0
      expect(game.reload).not_to be_finished
    end
  end

  describe '#draw_card!' do
    context 'デッキにカードがある場合' do
      let!(:deck_card) { create(:game_card, game: game, user: user, game_player: player, card: card_master, location: :deck, position_in_stack: 0) }

      it '手札に移動し、drawログ（カード名入り）が記録されること' do
        expect {
          player.draw_card!
        }.to change(BattleLog, :count).by(1)

        expect(deck_card.reload.location).to eq 'hand'

        log = BattleLog.last
        expect(log.event_type).to eq 'draw'
        expect(log.details['card_name']).to eq 'テストカード'
        expect(log.details['key_code']).to eq 'test_c'
      end
    end

    context 'デッキが空の場合' do
      it 'nilを返す（ゲーム終了判定は呼び出し元で行う）' do
        result = player.draw_card!

        expect(result).to be_nil
        # モデルはnilを返すのみ、ゲーム終了判定は行わない
        expect(game.reload).not_to be_finished
      end
    end
  end

  describe '#discard_card!' do
    let!(:hand_card) { create(:game_card, game: game, user: user, game_player: player, card: card_master, location: :hand) }

    context '引数なし（手動）の場合' do
      it '墓地に移動し、reason: manual でログが記録されること' do
        expect {
          player.discard_card!(hand_card)
        }.to change(BattleLog, :count).by(1)

        expect(hand_card.reload.location).to eq 'graveyard'

        log = BattleLog.last
        expect(log.event_type).to eq 'discard'
        expect(log.details['card_name']).to eq 'テストカード'
        expect(log.details['reason']).to eq 'manual'
      end
    end

    context '理由を指定した場合（効果による破棄など）' do
      it 'reason が指定した値で記録されること' do
        player.discard_card!(hand_card, reason: 'random_effect')

        log = BattleLog.last
        expect(log.event_type).to eq 'discard'
        expect(log.details['reason']).to eq 'random_effect'
      end
    end

    context '手札にない（例えばデッキにある）カードを指定した場合' do
      let(:deck_card) { create(:game_card, game: game, user: user, game_player: player, card: card_master, location: :deck) }

      it 'ArgumentErrorが発生すること' do
        expect {
          player.discard_card!(deck_card)
        }.to raise_error(ArgumentError, /not in player's hand/)
      end
    end

    context '他人のカードを指定した場合' do
      let(:other_user) { create(:user) }
      let(:other_player) { create(:game_player, game: game, user: other_user) }
      let(:other_card) { create(:game_card, game: game, user: other_user, game_player: other_player, card: card_master, location: :hand) }

      it 'ArgumentErrorが発生すること' do
        expect {
          player.discard_card!(other_card)
        }.to raise_error(ArgumentError, /not in player's hand/)
      end
    end
  end

  describe '#insane?' do
    it 'SAN値が0以下ならtrueを返す' do
      player.san = 0
      expect(player).to be_insane

      player.san = 1
      expect(player).not_to be_insane
    end
  end
end
