require 'rails_helper'

RSpec.describe GameCard, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:game_player) { create(:game_player, game: game, user: user, san: 20) }

  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :unit, key_code: "test_unit", threshold_san: 10) }

  let(:game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: card, location: :deck) }
  describe 'associations' do
    it 'has_many moves with dependent: :destroy' do
      assc = described_class.reflect_on_association(:moves)
      expect(assc.macro).to eq :has_many
      expect(assc.options[:dependent]).to eq :destroy
    end
  end

  describe '#total_attack' do
    context '数値のみの場合' do
      it '文字列の数値を返すこと' do
        game_card.update!(current_attack: "3")
        expect(game_card.total_attack).to eq "3"
      end

      it 'バフがある場合、加算された数値を文字列で返すこと' do
        game_card.update!(current_attack: "3")
        game_card.modifiers.create!(effect_type: :attack_buff, value: 2, duration: 1, modification_type: :temporary)
        expect(game_card.total_attack).to eq "5"
      end
    end

    context 'ダイス記法(1d6)の場合' do
      it 'ダイス記法をそのまま返すこと' do
        game_card.update!(current_attack: "1d6")
        expect(game_card.total_attack).to eq "1d6"
      end

      it 'バフがある場合、+N を付与した文字列を返すこと' do
        game_card.update!(current_attack: "1d6")
        game_card.modifiers.create!(effect_type: :attack_buff, value: 2, duration: 1, modification_type: :temporary)
        expect(game_card.total_attack).to eq "1d6+2"
      end

      it '負のバフがある場合、+-N ではなく -N の形式で返すこと' do
        game_card.update!(current_attack: "1d6")
        game_card.modifiers.create!(effect_type: :attack_buff, value: -2, duration: 1, modification_type: :temporary)
        expect(game_card.total_attack).to eq "1d6-2"
      end
    end
  end

  describe '状態遷移' do
    context '#move_to_hand!' do
      it '手札に移動すること' do
        game_card.move_to_hand!(0)

        expect(game_card.location).to eq 'hand'
      end
    end

    context '#discard!' do
      it '墓地に移動すること' do
        game_card.discard!

        expect(game_card.location).to eq 'graveyard'
      end
    end

    context '#summon_to!' do
      it '盤面に移動すること' do
        game_card.summon_to!(:center)

        expect(game_card.location).to eq 'board'
        expect(game_card.position).to eq 'center'
      end
    end

    context 'ターンの作成順序がID順と異なる場合' do
      before do
        game.turns.destroy_all
        create(:turn, game: game, turn_number: 2)
        create(:turn, game: game, turn_number: 1)
      end

      it 'turn_numberに基づいて最新のターンを取得する' do
        game_card.summon_to!(:center)
        expect(game_card.summoned_turn).to eq 2
      end
    end
  end

  describe '#trigger' do
    let(:normal_effect_step) { instance_double(CardEffects::Steps::BaseStep) }
    let(:insane_effect_step) { instance_double(CardEffects::Steps::BaseStep) }

    let(:effect_definition) do
      definition = CardEffects::EffectDefinition.new({
        on_attack: [ normal_effect_step ],
        on_attack_insane: [ insane_effect_step ]
      })
      definition
    end

    before do
      allow(CardEffects::Registry).to receive(:find).with("test_unit").and_return(effect_definition)
    end

    context '通常時 (SAN: 20 > 閾値 10)' do
      it '通常効果(:on_attack)が実行され、ログの is_insane が false であること' do
        expect(normal_effect_step).to receive(:call).with(instance_of(CardEffects::Context))

        game_card.trigger(:on_attack)

        log = BattleLog.last
        expect(log.event_type).to eq 'effect_trigger'
        expect(log.details['timing'].to_s).to eq 'on_attack'
        expect(log.details['is_insane']).to be false
      end
    end

    context '狂気時 (SAN: 5 <= 閾値 10)' do
      before do
        game_player.update!(san: 5)
      end

      it '狂気効果(:on_attack_insane)が実行され、ログの is_insane が true であること' do
        expect(insane_effect_step).to receive(:call).with(instance_of(CardEffects::Context))

        game_card.trigger(:on_attack)

        log = BattleLog.last
        expect(log.details['timing'].to_s).to eq 'on_attack_insane'
        expect(log.details['is_insane']).to be true
      end
    end

    context '狂気条件は満たしているが、狂気用エフェクトが定義されていない場合' do
      let(:effect_definition) do
        CardEffects::EffectDefinition.new({
          on_attack: [ normal_effect_step ]
        })
      end

      before do
        game_player.update!(san: 5)
      end

      it '通常効果にフォールバックして実行されること' do
        expect(normal_effect_step).to receive(:call).with(instance_of(CardEffects::Context))

        game_card.trigger(:on_attack)

        log = BattleLog.last
        expect(log.details['is_insane']).to be false
      end
    end
  end
end
