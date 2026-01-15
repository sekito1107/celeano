require 'rails_helper'

RSpec.describe RevealCards, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  describe '#call' do
    context '予約中のユニットがある場合' do
      let(:unit_card) { create(:card, :unit) }
      let!(:resolving_unit) do
        create(:game_card,
          game: game,
          user: user,
          game_player: player,
          card: unit_card,
          location: :resolving,
          position: :center
        )
      end

      it 'ユニットがボードに配置される' do
        described_class.call(game: game, turn: turn)

        resolving_unit.reload
        expect(resolving_unit.location).to eq 'board'
        expect(resolving_unit.position).to eq 'center'
      end

      it 'summoned_turnが現在のターン番号に設定される' do
        described_class.call(game: game, turn: turn)

        expect(resolving_unit.reload.summoned_turn).to eq 1
      end

      it 'unit_revealed BattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change(BattleLog, :count).by(1)

        log = BattleLog.last
        expect(log.event_type).to eq 'unit_revealed'
        expect(log.details['card_id']).to eq resolving_unit.id
      end

      it 'on_play効果がトリガーされる' do
        effect_called = false
        play_step = instance_double(CardEffects::Steps::BaseStep)
        allow(play_step).to receive(:call) { effect_called = true }

        effect_definition = CardEffects::EffectDefinition.new({
          on_play: [ play_step ]
        })
        allow(CardEffects::Registry).to receive(:find).with(unit_card.key_code).and_return(effect_definition)

        described_class.call(game: game, turn: turn)

        expect(effect_called).to be true
      end
    end

    context '予約中のスペルがある場合' do
      let(:spell_card) { create(:card, :spell) }
      let!(:resolving_spell) do
        create(:game_card,
          game: game,
          user: user,
          game_player: player,
          card: spell_card,
          location: :resolving
        )
      end

      it 'スペルはRevealCardsでは処理されない（ResolveSpellsで処理される）' do
        described_class.call(game: game, turn: turn)

        # スペルはresolving状態のまま
        expect(resolving_spell.reload.location).to eq 'resolving'
      end
    end

    context '複数のプレイヤーがカードを予約している場合' do
      let(:unit_card1) { create(:card, :unit) }
      let(:unit_card2) { create(:card, :unit) }
      let!(:player_unit) do
        create(:game_card,
          game: game,
          user: user,
          game_player: player,
          card: unit_card1,
          location: :resolving,
          position: :left
        )
      end
      let!(:opponent_unit) do
        create(:game_card,
          game: game,
          user: opponent_user,
          game_player: opponent,
          card: unit_card2,
          location: :resolving,
          position: :right
        )
      end

      it '両プレイヤーのユニットが同時にボードに配置される' do
        described_class.call(game: game, turn: turn)

        expect(player_unit.reload.location).to eq 'board'
        expect(opponent_unit.reload.location).to eq 'board'
      end

      it '両方のBattleLogが作成される' do
        expect {
          described_class.call(game: game, turn: turn)
        }.to change(BattleLog, :count).by(2)
      end
    end

    context '予約中のカードがない場合' do
      it 'エラーにならない' do
        result = described_class.call(game: game, turn: turn)

        expect(result).to be_a_success
      end

      it 'BattleLogは作成されない' do
        expect {
          described_class.call(game: game, turn: turn)
        }.not_to change(BattleLog, :count)
      end
    end
  end
end
