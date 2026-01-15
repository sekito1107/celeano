require 'rails_helper'

RSpec.describe DetermineAttackTargets, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit) }

  describe '#call' do
    context '正面に敵がいる場合' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 0)
      end
      let!(:front_enemy) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :center, summoned_turn: 1)
      end

      it '正面の敵をターゲットにする' do
        result = described_class.call(game: game)

        attacker_plan = result.attack_plan.find { |p| p[:attacker] == attacker }
        expect(attacker_plan).to be_present
        expect(attacker_plan[:target]).to eq front_enemy
        expect(attacker_plan[:target_type]).to eq :unit
      end
    end

    context '正面に敵がおらず、守護持ちがいる場合' do
      let(:guardian_card) { create(:card, :unit, :with_guardian) }
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 0)
      end
      let!(:guardian_enemy) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: guardian_card, location: :board, position: :left, summoned_turn: 1)
      end

      it '守護持ちをターゲットにする' do
        result = described_class.call(game: game)

        attacker_plan = result.attack_plan.find { |p| p[:attacker] == attacker }
        expect(attacker_plan).to be_present
        expect(attacker_plan[:target]).to eq guardian_enemy
        expect(attacker_plan[:target_type]).to eq :unit
      end
    end

    context '敵ユニットがいない場合' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 0)
      end

      it '相手プレイヤーを直接攻撃する' do
        result = described_class.call(game: game)

        expect(result.attack_plan.size).to eq 1
        expect(result.attack_plan.first[:target]).to eq opponent
        expect(result.attack_plan.first[:target_type]).to eq :player
      end
    end

    context '召喚酔い中のユニット' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 1)
      end

      it '攻撃しない' do
        result = described_class.call(game: game)

        expect(result.attack_plan).to be_empty
      end
    end

    context '速攻持ちのユニット（召喚ターン）' do
      let(:haste_card) { create(:card, :unit, :with_haste) }
      let!(:haste_attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: haste_card, location: :board, position: :center, summoned_turn: 1)
      end

      it '召喚ターンでも攻撃できる' do
        result = described_class.call(game: game)

        expect(result.attack_plan.size).to eq 1
        expect(result.attack_plan.first[:attacker]).to eq haste_attacker
      end
    end

    context 'スタン状態のユニット' do
      let!(:stunned_attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 0)
      end
      let!(:stun_modifier) { create(:game_card_modifier, :stun, game_card: stunned_attacker) }

      it '攻撃しない' do
        result = described_class.call(game: game)

        expect(result.attack_plan).to be_empty
      end
    end

    context '複数の守護持ちがいる場合' do
      let(:guardian_card) { create(:card, :unit, :with_guardian) }
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, summoned_turn: 0)
      end

      context 'HPが異なる場合' do
        let!(:guardian_high_hp) do
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: guardian_card, location: :board, position: :right, current_hp: 5, summoned_turn: 1)
        end
        let!(:guardian_low_hp) do
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: guardian_card, location: :board, position: :left, current_hp: 3, summoned_turn: 1)
        end

        it 'HPが高い守護がターゲットになる' do
          result = described_class.call(game: game)

          attacker_plan = result.attack_plan.find { |p| p[:attacker] == attacker }
          expect(attacker_plan[:target]).to eq guardian_high_hp
        end
      end

      context 'HPが同じ場合' do
        let!(:guardian_right) do
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: guardian_card, location: :board, position: :right, current_hp: 4, summoned_turn: 1)
        end
        let!(:guardian_left) do
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: guardian_card, location: :board, position: :left, current_hp: 4, summoned_turn: 1)
        end

        it '左側のポジションにいる守護がターゲットになる' do
          result = described_class.call(game: game)

          attacker_plan = result.attack_plan.find { |p| p[:attacker] == attacker }
          expect(attacker_plan[:target]).to eq guardian_left
        end
      end
    end
  end
end
