require 'rails_helper'

RSpec.describe CardEffects::Definitions::CthulhuSpells do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let(:player) { create(:game_player, game: game, user: user) }
  let(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let(:card_source) { create(:game_card, game: game, game_player: player, card: create(:card, card_type: :spell)) }

  # コンテキストヘルパー
  def create_context(target: nil)
    create(:turn, game: game, turn_number: 1) if game.turns.empty?
    CardEffects::Context.new(
      source_card: card_source,
      target: target,
      timing: :on_play
    )
  end

  describe "call_of_the_deep" do
    let(:effect) { described_class.effects["call_of_the_deep"] }
    let(:target_unit) { create(:game_card, game: game, game_player: opponent, location: :board, current_hp: 5, card: create(:card, card_type: :unit)) }



    it "対象のユニットに3ダメージを与える" do
      context = create_context(target: target_unit)

      expect {
        effect.execute(:on_play, context)
      }.to change { target_unit.reload.current_hp }.by(-3)
    end
  end

  describe "rlyeh_rising" do
    let(:effect) { described_class.effects["rlyeh_rising"] }
    let!(:unit1) { create(:game_card, game: game, game_player: player, location: :board, current_attack: "2", card: create(:card, card_type: :unit)) }
    let!(:unit2) { create(:game_card, game: game, game_player: player, location: :board, current_attack: "3", card: create(:card, card_type: :unit)) }
    let!(:enemy_unit) { create(:game_card, game: game, game_player: opponent, location: :board, current_attack: "2", card: create(:card, card_type: :unit)) }

    it "自分の全ユニットの攻撃力を+2する" do
      context = create_context

      effect.execute(:on_play, context)

      expect(unit1.reload.total_attack).to eq("4")
      expect(unit2.reload.total_attack).to eq("5")
      expect(enemy_unit.reload.total_attack).to eq("2") # 敵には影響しない

      # モディファイアが付与されているか
      expect(unit1.modifiers.count).to eq(1)
      expect(unit1.modifiers.exists?(effect_type: "attack_buff", duration: 1)).to be true
    end
  end

  describe "ocean_embrace" do
    let(:effect) { described_class.effects["ocean_embrace"] }
    let(:target_unit) { create(:game_card, game: game, game_player: player, location: :board, current_hp: 2, card: create(:card, card_type: :unit, hp: 5)) }

    it "対象のユニットのHPを3回復する" do
      context = create_context(target: target_unit)

      expect {
        effect.execute(:on_play, context)
      }.to change { target_unit.reload.current_hp }.by(3)
    end

    context "回復量が最大HPを超える場合" do
      let(:target_unit) { create(:game_card, game: game, game_player: player, location: :board, current_hp: 4, card: create(:card, card_type: :unit, hp: 5)) }

      it "最大HPまで回復する" do
        context = create_context(target: target_unit)
        effect.execute(:on_play, context)
        expect(target_unit.reload.current_hp).to eq(5)
      end
    end
  end

  describe "tidal_wave" do
    let(:effect) { described_class.effects["tidal_wave"] }
    let!(:unit1) { create(:game_card, game: game, game_player: opponent, location: :board, current_hp: 3, card: create(:card, card_type: :unit)) }
    let!(:unit2) { create(:game_card, game: game, game_player: opponent, location: :board, current_hp: 2, card: create(:card, card_type: :unit)) }
    let!(:ally_unit) { create(:game_card, game: game, game_player: player, location: :board, current_hp: 3, card: create(:card, card_type: :unit)) }

    it "敵の全ユニットに2ダメージを与える" do
      context = create_context

      effect.execute(:on_play, context)

      expect(unit1.reload.current_hp).to eq(1)
      expect(unit2.reload.current_hp).to eq(0) # 死亡処理は別途行われるがHPは0になる
      expect(ally_unit.reload.current_hp).to eq(3) # 味方には影響しない
    end
  end

  describe "cthulhu_dream" do
    let(:effect) { described_class.effects["cthulhu_dream"] }
    let(:target_unit) { create(:game_card, game: game, game_player: opponent, location: :board, card: create(:card, card_type: :unit)) }

    it "対象のユニットをスタン状態にする" do
      context = create_context(target: target_unit)

      effect.execute(:on_play, context)

      expect(target_unit.modifiers.exists?(effect_type: :stun)).to be true
    end
  end
end
