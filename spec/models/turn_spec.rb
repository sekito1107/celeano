require 'rails_helper'

RSpec.describe Turn, type: :model do
  describe '#unit_summon_limit' do
    it 'ラウンド数に応じて上限が変わる' do
      expect(build(:turn, turn_number: 1).unit_summon_limit).to eq 1
      expect(build(:turn, turn_number: 2).unit_summon_limit).to eq 1
      expect(build(:turn, turn_number: 3).unit_summon_limit).to eq 2
      expect(build(:turn, turn_number: 4).unit_summon_limit).to eq 2
      expect(build(:turn, turn_number: 5).unit_summon_limit).to eq 3
      expect(build(:turn, turn_number: 6).unit_summon_limit).to eq 3
      expect(build(:turn, turn_number: 10).unit_summon_limit).to eq 3
    end
  end

  describe '#units_summoned_count' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:turn) { create(:turn, game: game, turn_number: 1) }

    let!(:player) { create(:game_player, game: game, user: user) }
    let!(:other_player) { create(:game_player, game: game, user: other_user) }

    let(:unit_card) { create(:card, :unit) }
    let(:spell_card) { create(:card, :spell) }

    let(:unit_game_card) { create(:game_card, game: game, user: user, game_player: player, card: unit_card) }
    let(:spell_game_card) { create(:game_card, game: game, user: user, game_player: player, card: spell_card) }


    it 'ユニットを召喚するとカウントされる' do
      create(:move, :play, turn: turn, user: user, game_card: unit_game_card)
      expect(turn.units_summoned_count(user)).to eq 1
    end

    it 'スペルをプレイしてもカウントされない' do
      create(:move, :spell, turn: turn, user: user, game_card: spell_game_card)
      expect(turn.units_summoned_count(user)).to eq 0
    end

    it '他人の召喚はカウントされない' do
      other_gc = create(:game_card, game: game, user: other_user, game_player: other_player, card: unit_card)
      create(:move, :play, turn: turn, user: other_user, game_card: other_gc)

      expect(turn.units_summoned_count(user)).to eq 0
    end

    it '別のターンの召喚はカウントされない' do
      other_turn = create(:turn, game: game, turn_number: 2)
      other_unit_game_card = create(:game_card, game: game, user: user, game_player: player, card: unit_card)
      create(:move, :play, turn: other_turn, user: user, game_card: other_unit_game_card)

      expect(turn.units_summoned_count(user)).to eq 0
    end
  end

  describe '#summon_limit_reached?' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let!(:player) { create(:game_player, game: game, user: user) }
    let(:turn) { create(:turn, game: game, turn_number: 1) }

    let(:unit_card) { create(:card, :unit) }
    let(:spell_card) { create(:card, :spell) }

    let(:unit_game_card) { create(:game_card, game: game, user: user, game_player: player, card: unit_card) }
    let(:spell_game_card) { create(:game_card, game: game, user: user, game_player: player, card: spell_card) }

    context 'まだ召喚していない場合（上限未達）' do
      it '初期状態ではfalseを返す' do
        expect(turn.summon_limit_reached?(user)).to be false
      end

      it 'スペルをプレイしてもfalseのまま' do
        create(:move, :spell, turn: turn, user: user, game_card: spell_game_card)
        expect(turn.summon_limit_reached?(user)).to be false
      end
    end

    context '上限まで召喚した場合' do
      before do
        create(:move, :play, turn: turn, user: user, game_card: unit_game_card)
      end

      it 'trueを返す' do
        expect(turn.summon_limit_reached?(user)).to be true
      end
    end
  end

  describe '#pending_cost_range_for' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let(:turn) { create(:turn, game: game) }
    let(:game_player) { create(:game_player, game: game, user: user) }

    context 'Moveがない場合' do
      it '[0, 0]を返すこと' do
        expect(turn.pending_cost_range_for(user)).to eq([ 0, 0 ])
      end
    end

    context '確定コストのMoveがある場合' do
      it 'そのコストを返すこと' do
        card = create(:card, cost: "3")
        gc = create(:game_card, game: game, card: card, user: user)
        create(:move, turn: turn, user: user, game_card: gc)

        expect(turn.pending_cost_range_for(user)).to eq([ 3, 3 ])
      end
    end

    context '範囲コスト(ダイス)のMoveがある場合' do
      it '最小値と最大値を返すこと' do
        card = create(:card, cost: "1d4")
        gc = create(:game_card, game: game, card: card, user: user)
        create(:move, turn: turn, user: user, game_card: gc)

        expect(turn.pending_cost_range_for(user)).to eq([ 1, 4 ])
      end
    end

    context '複数のMoveがある場合' do
      it '合算値を返すこと' do
        card1 = create(:card, cost: "2")
        card2 = create(:card, cost: "1d6")

        gc1 = create(:game_card, game: game, card: card1, user: user, game_player: game_player)
        gc2 = create(:game_card, game: game, card: card2, user: user, game_player: game_player)

        create(:move, turn: turn, user: user, game_card: gc1)
        create(:move, turn: turn, user: user, game_card: gc2)

        # 2 + [1, 6] = [3, 8]
        expect(turn.pending_cost_range_for(user)).to eq([ 3, 8 ])
      end
    end
  end
end
