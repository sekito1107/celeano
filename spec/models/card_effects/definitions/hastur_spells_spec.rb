require 'rails_helper'

RSpec.describe CardEffects::Definitions::HasturSpells do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, :guest, game: game, user: opponent_user, san: 10) }
  let(:card_source) { create(:game_card, game: game, game_player: player, card: create(:card, card_type: :spell)) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  # コンテキストヘルパー
  def create_context(target: nil)
    CardEffects::Context.new(
      source_card: card_source,
      target: target,
      timing: :on_play
    )
  end

  describe "yellow_sign" do
    let(:effect) { described_class.effects["yellow_sign"] }
    let(:target_unit) { create(:game_card, game: game, game_player: opponent, location: :board, card: create(:card, card_type: :unit)) }

    it "対象のユニットをスタン状態にする" do
      context = create_context(target: target_unit)

      effect.execute(:on_play, context)

      expect(target_unit.modifiers.exists?(effect_type: :stun)).to be true
    end
  end

  describe "madness_whisper" do
    let(:effect) { described_class.effects["madness_whisper"] }

    it "相手プレイヤーのSAN値を3減少させる" do
      context = create_context

      expect {
        effect.execute(:on_play, context)
      }.to change { opponent.reload.san }.by(-3)
    end
  end

  describe "carcosa_vision" do
    let(:effect) { described_class.effects["carcosa_vision"] }
    let(:target_unit) { create(:game_card, game: game, game_player: opponent, location: :board, card: create(:card, card_type: :unit)) }

    it "対象のユニットに毒(2)を付与する" do
      context = create_context(target: target_unit)

      effect.execute(:on_play, context)

      modifier = target_unit.modifiers.find_by(effect_type: :poison)
      expect(modifier).to be_present
      expect(modifier.value).to eq(2)
      expect(modifier.duration).to eq(3)
    end
  end

  describe "kings_presence" do
    let(:effect) { described_class.effects["kings_presence"] }
    let!(:unit1) { create(:game_card, game: game, game_player: opponent, location: :board, card: create(:card, card_type: :unit)) }
    let!(:unit2) { create(:game_card, game: game, game_player: opponent, location: :board, card: create(:card, card_type: :unit)) }
    let!(:ally_unit) { create(:game_card, game: game, game_player: player, location: :board, card: create(:card, card_type: :unit)) }

    it "敵の全ユニットをスタン状態にする" do
      context = create_context

      effect.execute(:on_play, context)

      expect(unit1.modifiers.exists?(effect_type: :stun)).to be true
      expect(unit2.modifiers.exists?(effect_type: :stun)).to be true
      expect(ally_unit.modifiers.exists?(effect_type: :stun)).to be false
    end
  end

  describe "unspeakable_oath" do
    let(:effect) { described_class.effects["unspeakable_oath"] }
    let(:target_unit) { create(:game_card, game: game, game_player: opponent, location: :board, current_hp: 5, card: create(:card, card_type: :unit)) }

    it "対象のユニットを破壊する" do
      context = create_context(target: target_unit)

      effect.execute(:on_play, context)

      target_unit.reload
      expect(target_unit.current_hp).to eq(0)
      expect(target_unit.location).to eq("graveyard")
    end
  end
end
