require 'rails_helper'

RSpec.describe ResolveSpells, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:spell_card) { create(:card, :spell, key_code: "test_spell") }
  let(:spell_game_card) { create(:game_card, game: game, user: user, game_player: player, card: spell_card, location: :resolving) }

  let(:target_card) { create(:card, :unit) }
  let(:target_game_card) { create(:game_card, game: game, user: opponent_user, game_player: opponent, card: target_card, location: :board, position: :center) }

  describe '#call' do
    context 'スペルの行動がある場合' do
      before do
        create(:move, :spell, turn: turn, user: user, game_card: spell_game_card, target_game_card: target_game_card)
      end

      it 'スペル発動のBattleLogが作成される' do
        expect {
          described_class.call(turn: turn, game: game)
        }.to change(BattleLog, :count).by(1)

        log = BattleLog.last
        expect(log.event_type).to eq "spell_activation"
        expect(log.details["key_code"]).to eq "test_spell"
      end

      it 'on_play効果がトリガーされる' do
        effect_called = false
        play_step = instance_double(CardEffects::Steps::BaseStep)
        allow(play_step).to receive(:call) { effect_called = true }

        effect_definition = CardEffects::EffectDefinition.new({
          on_play: [ play_step ]
        })
        allow(CardEffects::Registry).to receive(:find).with("test_spell").and_return(effect_definition)

        described_class.call(turn: turn, game: game)

        expect(effect_called).to be true
      end

      it 'スペルは効果発動後に墓地へ移動する' do
        described_class.call(turn: turn, game: game)

        expect(spell_game_card.reload.location).to eq 'graveyard'
      end
    end

    context 'スペルの行動がない場合' do
      it 'BattleLogは作成されない' do
        expect {
          described_class.call(turn: turn, game: game)
        }.not_to change(BattleLog, :count)
      end
    end

    context '効果の実行中にエラーが発生した場合' do
      before do
        create(:move, :spell, turn: turn, user: user, game_card: spell_game_card, target_game_card: target_game_card)

        # エラーを発生させる効果を定義してRegistryに登録
        error_step = instance_double(CardEffects::Steps::BaseStep)
        allow(error_step).to receive(:call).and_raise(StandardError, "Effect error")

        error_effect = CardEffects::EffectDefinition.new({ on_play: [ error_step ] })
        allow(CardEffects::Registry).to receive(:find).with("test_spell").and_return(error_effect)
      end

      it '効果実行中にエラーが発生する' do
        expect {
          described_class.call(turn: turn, game: game)
        }.to raise_error(StandardError, "Effect error")
      end

      it 'BattleLogは作成されない（ロールバックされる）' do
        expect {
          begin
            described_class.call(turn: turn, game: game)
          rescue StandardError
          end
        }.not_to change(BattleLog, :count)
      end
    end

    context 'ゲームが終了している場合' do
      before do
        create(:move, :spell, turn: turn, user: user, game_card: spell_game_card, target_game_card: target_game_card)
        game.update!(status: :finished)
      end

      it 'スペル処理がスキップされること' do
        expect {
          described_class.call(turn: turn, game: game)
        }.not_to change(BattleLog, :count)
      end

      it 'スペルが墓地に移動しないこと' do
        described_class.call(turn: turn, game: game)

        expect(spell_game_card.reload.location).to eq 'resolving'
      end
    end
  end
end
