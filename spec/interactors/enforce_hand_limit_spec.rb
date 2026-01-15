require 'rails_helper'

RSpec.describe EnforceHandLimit, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit) }

  describe '#call' do
    context '手札が7枚以下の場合' do
      before do
        5.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
      end

      it 'カードは捨てられない' do
        expect {
          described_class.call(game: game)
        }.not_to change { player.hand.count }
      end
    end

    context '手札が8枚の場合' do
      before do
        8.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
      end

      it '1枚捨てられて7枚になる' do
        described_class.call(game: game)

        expect(player.reload.hand.count).to eq 7
      end

      it '最後に引いたカード(position_in_stack最大)が捨てられる' do
        # 8枚の手札のうち最大position_in_stackは7
        expect(player.hand.maximum(:position_in_stack)).to eq 7

        cards = player.hand.order(:position_in_stack).to_a
        last_card = cards.last

        described_class.call(game: game)

        expect(last_card.reload.location).to eq 'graveyard'
        expect(player.reload.hand.count).to eq 7
      end

      it 'hand_limit理由でdiscardログが記録される' do
        expect {
          described_class.call(game: game)
        }.to change { BattleLog.where(event_type: "discard").count }.by(1)

        log = BattleLog.where(event_type: "discard").last
        expect(log.details["reason"]).to eq "hand_limit"
      end
    end

    context '手札が10枚の場合' do
      before do
        10.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
      end

      it '3枚捨てられて7枚になる' do
        described_class.call(game: game)

        expect(player.reload.hand.count).to eq 7
      end
    end

    context '両プレイヤーが制限を超えている場合' do
      let(:opponent_user) { create(:user) }
      let!(:opponent) { create(:game_player, game: game, user: opponent_user) }

      before do
        # プレイヤー1: 8枚
        8.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
        # プレイヤー2: 9枚
        9.times do |i|
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
      end

      it '両プレイヤーとも7枚になる' do
        described_class.call(game: game)

        expect(player.reload.hand.count).to eq 7
        expect(opponent.reload.hand.count).to eq 7
      end
    end

    context 'ゲームが終了している場合' do
      before do
        game.update!(status: :finished)

        # 手札を8枚にする
        8.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :hand, position_in_stack: i)
        end
      end

      it '手札制限が適用されないこと' do
        expect {
          described_class.call(game: game)
        }.not_to change { player.hand.count }

        expect(player.reload.hand.count).to eq 8
      end
    end
  end
end
