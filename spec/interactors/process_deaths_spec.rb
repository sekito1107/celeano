require 'rails_helper'

RSpec.describe ProcessDeaths, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit, key_code: "dying_unit") }

  describe '#call' do
    context 'HPが0以下のユニットがいる場合' do
      let!(:dead_unit) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_hp: 0)
      end

      it 'ユニットが墓地に移動する' do
        described_class.call(game: game, turn: turn)

        dead_unit.reload
        expect(dead_unit.location).to eq "graveyard"
      end

      it 'on_death効果がトリガーされる' do
        death_triggered = false
        death_step = instance_double(CardEffects::Steps::BaseStep)
        allow(death_step).to receive(:call) { death_triggered = true }

        effect_definition = CardEffects::EffectDefinition.new({
          on_death: [ death_step ]
        })
        allow(CardEffects::Registry).to receive(:find).with("dying_unit").and_return(effect_definition)

        described_class.call(game: game, turn: turn)

        expect(death_triggered).to be true
      end

      it 'BattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change(BattleLog, :count).by(1)

        log = BattleLog.last
        expect(log.event_type).to eq "unit_death"
        expect(log.details["key_code"]).to eq "dying_unit"
      end

      it 'dead_unitsがcontextに設定される' do
        result = described_class.call(game: game, turn: turn)

        expect(result.dead_units.map(&:id)).to contain_exactly(dead_unit.id)
      end
    end

    context '複数のユニットが死亡する場合' do
      let!(:dead_unit1) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :left, current_hp: 0)
      end
      let!(:dead_unit2) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :right, current_hp: -1)
      end
      let!(:alive_unit) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_hp: 3)
      end

      it '全ての死亡ユニットが墓地に移動する' do
        described_class.call(game: game, turn: turn)

        expect(dead_unit1.reload.location).to eq "graveyard"
        expect(dead_unit2.reload.location).to eq "graveyard"
        expect(alive_unit.reload.location).to eq "board"
      end

      it '死亡ユニット数分のBattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change(BattleLog, :count).by(2)
      end
    end

    context '死亡ユニットがいない場合' do
      let!(:alive_unit) do
        create(:game_card, game: game, user: user, game_player: player,
               card: unit_card, location: :board, position: :center, current_hp: 5)
      end

      it 'BattleLogは作成されない' do
        expect {
          described_class.call(game: game, turn: turn)
        }.not_to change(BattleLog, :count)
      end

      it 'dead_unitsは空' do
        result = described_class.call(game: game, turn: turn)

        expect(result.dead_units).to be_empty
      end
    end
  end
end
