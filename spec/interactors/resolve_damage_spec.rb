require 'rails_helper'

RSpec.describe ResolveDamage, type: :interactor do
  let(:game) { create(:game, seed: 12345) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user, hp: 20) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user, hp: 20) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit, attack: "3", hp: 5) }

  describe '#call' do
    context 'ユニットへの攻撃' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_attack: "3")
      end
      let!(:target) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :center, current_hp: 5)
      end

      let(:attack_plan) do
        [ { attacker: attacker, target: target, target_type: :unit } ]
      end

      it 'ターゲットのHPが減少する' do
        described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        target.reload
        expect(target.current_hp).to be < 5
      end

      it 'BattleLogが作成される' do
        expect {
          described_class.call(attack_plan: attack_plan, game: game, turn: turn)
        }.to change(BattleLog, :count).by(1)

        log = BattleLog.last
        expect(log.event_type).to eq "attack"
        expect(log.details["target_type"]).to eq "unit"
      end

      it 'damage_resultsがcontextに設定される' do
        result = described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        expect(result.damage_results).to be_present
        expect(result.damage_results.first[:attacker]).to eq attacker
        expect(result.damage_results.first[:damage]).to be > 0
      end
    end

    context 'プレイヤーへの直接攻撃' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_attack: "3")
      end

      let(:attack_plan) do
        [ { attacker: attacker, target: opponent, target_type: :player } ]
      end

      it 'プレイヤーのHPが減少する' do
        described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        opponent.reload
        expect(opponent.hp).to be < 20
      end

      it 'BattleLogにプレイヤー攻撃として記録される' do
        described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        log = BattleLog.find_by(event_type: "attack")
        expect(log).to be_present
        expect(log.details["target_player_id"]).to eq opponent.id
      end
    end

    context '複数の攻撃が同時に発生する場合' do
      let!(:attacker1) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :left, current_attack: "2")
      end
      let!(:attacker2) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :right, current_attack: "2")
      end
      let!(:target) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :center, current_hp: 10)
      end

      let(:attack_plan) do
        [
          { attacker: attacker1, target: target, target_type: :unit },
          { attacker: attacker2, target: target, target_type: :unit }
        ]
      end

      it '全ての攻撃が同時に解決される（合計ダメージが適用される）' do
        result = described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        target.reload
        total_damage = result.damage_results.sum { |r| r[:damage] }
        expect(target.current_hp).to eq(10 - total_damage)
      end

      it '複数のBattleLogが作成される' do
        expect {
          described_class.call(attack_plan: attack_plan, game: game, turn: turn)
        }.to change(BattleLog, :count).by(2)
      end
    end

    context '攻撃途中でゲームが終了する場合' do
      let!(:attacker1) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :left, current_attack: "20")
      end
      let!(:attacker2) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :right, current_attack: "5")
      end

      # 最初の攻撃でプレイヤーが死ぬようにする
      let(:attack_plan) do
        [
          { attacker: attacker1, target: opponent, target_type: :player },
          { attacker: attacker2, target: opponent, target_type: :player }
        ]
      end

      it 'ゲーム終了後の攻撃は処理されない' do
        # 実行前の確認
        expect(opponent.hp).to eq 20
        expect(game.finished?).to be false

        expect {
          described_class.call(attack_plan: attack_plan, game: game, turn: turn)
        }.to change { BattleLog.where(event_type: "attack").count }.by(2)

        # ゲームは終了している
        game.reload
        expect(game.finished?).to be true

        # 敗北判定のログが出ているか確認
        expect(BattleLog.exists?(event_type: 'game_finish')).to be true
      end
    end

    context '双方が同時に致命傷を受ける場合（相打ち / HP Draw）' do
      let!(:attacker_p1) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :left, current_attack: "20")
      end
      let!(:attacker_p2) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :right, current_attack: "20")
      end

      # 攻撃プラン: P1のユニット -> P2本体, P2のユニット -> P1本体
      let(:attack_plan) do
        [
          { attacker: attacker_p1, target: opponent, target_type: :player },
          { attacker: attacker_p2, target: player, target_type: :player }
        ]
      end

      it 'HP DRAW（相打ち）としてゲームが終了する' do
        opponent.update!(hp: 20)

        described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        game.reload
        expect(game.finished?).to be true
        expect(game.finish_reason).to eq("HP_DRAW")
        expect(game.winner_id).to be_nil
        expect(game.loser_id).to be_nil

        # ログ確認
        finish_log = BattleLog.find_by(event_type: "game_finish")
        expect(finish_log.details['reason']).to eq("HP_DRAW")
        expect(finish_log.details['is_draw']).to be true
      end
    end

    context '攻撃時効果（on_attack）の発動' do
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_attack: "3")
      end
      let!(:target) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :center, current_hp: 10)
      end

      let(:attack_plan) do
        [ { attacker: attacker, target: target, target_type: :unit } ]
      end

      it '攻撃時にtrigger(:on_attack)が呼び出される' do
        expect(attacker).to receive(:trigger).with(:on_attack, target)

        described_class.call(attack_plan: attack_plan, game: game, turn: turn)
      end

      it '攻撃時バフがダメージ計算に反映される' do
        # 攻撃前にバフを付与するモック
        allow(attacker).to receive(:trigger).with(:on_attack, target) do
          attacker.modifiers.create!(
            effect_type: :attack_buff,
            modification_type: :temporary,
            value: 5,
            duration: 1
          )
        end

        result = described_class.call(attack_plan: attack_plan, game: game, turn: turn)

        # ダメージが基本攻撃力(3) + バフ(5) = 8 になること
        expect(result.damage_results.first[:damage]).to eq(8)
      end
    end

    context '狂気状態での攻撃時効果' do
      let(:madness_card) { create(:card, :unit, key_code: "test_madness", attack: "2", hp: 5, threshold_san: 10) }
      let!(:attacker) do
        create(:game_card, game: game, user: user, game_player: player,
               card: madness_card, location: :board, position: :center, current_attack: "2")
      end
      let!(:target) do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: unit_card, location: :board, position: :center, current_hp: 10)
      end

      let(:attack_plan) do
        [ { attacker: attacker, target: target, target_type: :unit } ]
      end

      it '正常時はon_attackが呼ばれる' do
        player.update!(san: 15) # 閾値(10)より上

        expect(attacker).to receive(:trigger).with(:on_attack, target)

        described_class.call(attack_plan: attack_plan, game: game, turn: turn)
      end

      it '狂気時もon_attackが呼ばれる（内部でon_attack_insaneに分岐）' do
        player.update!(san: 5) # 閾値(10)以下

        expect(attacker).to receive(:trigger).with(:on_attack, target)

        described_class.call(attack_plan: attack_plan, game: game, turn: turn)
      end
    end
  end
end
