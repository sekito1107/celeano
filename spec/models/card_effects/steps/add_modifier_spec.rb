require 'rails_helper'

RSpec.describe CardEffects::Steps::AddModifier, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :unit) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :board, position: :center)
  end

  let(:target_card) { create(:card, :unit) }
  let(:target_game_card) do
    create(:game_card, game: game, user: opponent_user, game_player: opponent,
           card: target_card, location: :board, position: :center)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: target_game_card,
      timing: :on_play
    )
  end

  describe '#call' do
    let(:self_timing) { :on_play }

    let(:self_context) do
      CardEffects::Context.new(
        source_card: game_card,
        target: game_card,
        timing: self_timing
      )
    end

    context 'スタンを付与する場合' do
      let(:step) { described_class.new(type: :stun, duration: 1, target: :selected_target) }

      it 'スタン状態になる' do
        step.call(context)
        expect(target_game_card.reload.stunned?).to be true
      end

      it 'GameCardModifierが作成される' do
        expect { step.call(context) }.to change(GameCardModifier, :count).by(1)
      end
    end

    context '攻撃力バフを付与する場合' do
      let(:step) { described_class.new(type: :attack_buff, value: 3, duration: 2, target: :self) }

      let(:self_timing) { :on_attack }

      it 'モディファイアが作成される' do
        step.call(self_context)
        modifier = game_card.modifiers.last
        expect(modifier.effect_type).to eq 'attack_buff'
        expect(modifier.value).to eq 3
        expect(modifier.duration).to eq 2
      end
    end

    context '毒を付与する場合' do
      let(:step) { described_class.new(type: :poison, value: 2, duration: 3, target: :selected_target) }

      it '毒モディファイアが作成される' do
        step.call(context)
        modifier = target_game_card.modifiers.last
        expect(modifier.effect_type).to eq 'poison'
        expect(modifier.value).to eq 2
        expect(modifier.duration).to eq 3
      end
    end

    context 'HPバフを付与する場合' do
      let(:step) { described_class.new(type: :hp_buff, value: 2, duration: 2, target: :self) }

      it 'HPバフモディファイアが作成される' do
        step.call(self_context)
        modifier = game_card.modifiers.last
        expect(modifier.effect_type).to eq 'hp_buff'
        expect(modifier.value).to eq 2
        expect(modifier.duration).to eq 2
        expect(modifier.modification_type).to eq 'temporary'
      end
    end

    context '永続的なモディファイアを付与する場合' do
      let(:step) { described_class.new(type: :attack_buff, value: 1, target: :self) }

      it 'durationを指定しない場合は永続的モディファイアになる' do
        step.call(self_context)
        modifier = game_card.modifiers.last
        expect(modifier.effect_type).to eq 'attack_buff'
        expect(modifier.value).to eq 1
        expect(modifier.duration).to be_nil
        expect(modifier.modification_type).to eq 'permanent'
      end
    end
  end
end
