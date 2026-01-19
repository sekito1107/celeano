require 'rails_helper'

RSpec.describe CreateMove, type: :interactor do
  describe '.call' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let(:turn) { create(:turn, game: game) }
    let(:game_player) { create(:game_player, game: game, user: user) }

    let(:unit_card) { create(:card, :unit) }
    let(:spell_card) { create(:card, :spell) }

    let(:unit_game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: unit_card) }
    let(:spell_game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: spell_card) }

    context 'ユニットカードの場合' do
      subject(:context) do
        described_class.call(
          turn: turn,
          game_player: game_player,
          game_card: unit_game_card,
          position: 1
        )
      end

      it '成功し、action_type: play, position: 1 で保存される' do
        expect(context).to be_a_success

        move = context.move
        expect(move).to be_persisted
        expect(move.game_card).to eq unit_game_card
        expect(move.action_type).to eq 'play'
        expect(move.position).to eq "center"
      end
    end

    context 'スペルカードの場合' do
      subject(:context) do
        described_class.call(
          turn: turn,
          game_player: game_player,
          game_card: spell_game_card,
          position: 1
        )
      end

      it '成功するが、positionは強制的にnilになり、action_type: spell で保存される' do
        expect(context).to be_a_success

        move = context.move
        expect(move).to be_persisted
        expect(move.game_card).to eq spell_game_card
        expect(move.action_type).to eq 'spell'
        expect(move.position).to be_nil
      end
    end

    context '異常系: 保存に失敗した場合（例：ユニットの範囲外配置）' do
      subject(:context) do
        described_class.call(
          turn: turn,
          game_player: game_player,
          game_card: unit_game_card,
          position: nil
        )
      end

      it '失敗し、エラーメッセージを返す' do
        expect(context).to be_a_failure
        expect(context.message).to include('カードの配置に失敗しました')
      end
    end
  end
end
