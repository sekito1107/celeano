require 'rails_helper'

RSpec.describe Dice, type: :model do
  describe '.roll' do
    context '固定値の場合' do
      it 'その数値を整数で返す' do
        expect(Dice.roll("5", 123, 0)).to eq 5
        expect(Dice.roll("100", 123, 0)).to eq 100
      end
    end

    context 'ダイス表記(XdY)の場合' do
      it '指定範囲内の数値が出る(1d6)' do
        results = 100.times.map { Dice.roll("1d6", 123, _1) }
        expect(results).to all(be_between(1, 6))
      end

      it '加算補正が機能する(1d6+10)' do
        results = 100.times.map { Dice.roll("1d6+10", 123, _1) }
        expect(results).to all(be_between(11, 16))
      end

      it '減算補正が機能する(1d6-1)' do
        results = 100.times.map { Dice.roll("1d6-1", 123, _1) }
        expect(results).to all(be_between(0, 5))
      end
    end

    context 'リプレイ性(Seed値)の検証' do
      let(:seed) { 99999 }
      let(:nonce) { 5 }
      let(:notation) { "1d1000000" }

      it '同じシードとnonceなら、必ず同じ結果になる' do
        result1 = Dice.roll(notation, seed, nonce)
        result2 = Dice.roll(notation, seed, nonce)

        expect(result1).to eq result2
      end

      it 'シードが同じでも、nonceが違えば(通常は)違う結果になる' do
        result_a = Dice.roll(notation, seed, 1)
        result_b = Dice.roll(notation, seed, 2)

        expect(result_a).not_to eq result_b
      end
    end

    context '異常系' do
      it '不正なフォーマットの場合はエラーが発生する' do
        expect { Dice.roll("invalid", 123, 0) }.to raise_error(NoMethodError)
        expect { Dice.roll("xdx", 123, 0) }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.range' do
    it 'parses simple number' do
      expect(Dice.range('5')).to eq([ 5, 5 ])
    end

    it 'parses NdM format' do
      expect(Dice.range('1d6')).to eq([ 1, 6 ])
    end

    it 'parses NdM+K format' do
      expect(Dice.range('2d6+3')).to eq([ 5, 15 ])
    end

    it 'parses NdM-K format' do
      expect(Dice.range('2d6-2')).to eq([ 0, 10 ])
    end

    it 'handles negative results by clamping to 0' do
      expect(Dice.range('1d4-10')).to eq([ 0, 0 ])
    end

    it 'handles invalid format gracefully' do
      expect(Dice.range('invalid')).to eq([ 0, 0 ])
    end
  end
end
