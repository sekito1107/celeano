require 'rails_helper'

RSpec.describe DamageCalculator do
  let(:game) { create(:game, seed: 12345) }
  let(:calculator) { described_class.new(game) }
  let(:card) { create(:card, attack: "1d6") }
  let(:game_card) { create(:game_card, game: game, card: card, current_attack: "1d6") }

  describe '#calculate_attack_power' do
    context '固定値の場合' do
      before { game_card.update!(current_attack: "3") }

      it 'その値を返すこと' do
        expect(calculator.calculate_attack_power(game_card)).to eq 3
      end

      it 'バフがある場合、加算されること' do
        game_card.modifiers.create!(effect_type: :attack_buff, value: 2, duration: 1, modification_type: :temporary)
        expect(calculator.calculate_attack_power(game_card)).to eq 5
      end
    end

    context 'ダイス記法(1d6)の場合' do
      it 'ダイスロールの結果を返すこと' do
        # Seed 12345 での最初のロール結果に依存するが、範囲内であることを確認
        result = calculator.calculate_attack_power(game_card)
        expect(result).to be_between(1, 6)
      end

      it 'バフがある場合、ダイス結果に加算されること' do
        game_card.modifiers.create!(effect_type: :attack_buff, value: 10, duration: 1, modification_type: :temporary)
        result = calculator.calculate_attack_power(game_card)
        expect(result).to be_between(11, 16)
      end
    end
  end
end
