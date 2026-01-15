require 'rails_helper'

RSpec.describe CardEffects::Steps::ReturnToHand, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game) }

  let(:card) { create(:card, :spell) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :hand)
  end

  let(:target_card) { create(:card, :unit, hp: 5) }
  let(:target_game_card) do
    create(:game_card, game: game, user: opponent_user, game_player: opponent,
           card: target_card, location: :board, position: :center, current_hp: 2)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: target_game_card,
      timing: :on_play
    )
  end

  describe '#call' do
    let(:step) { described_class.new(target: :selected_target) }

    it 'ターゲットが手札に戻る' do
      step.call(context)
      expect(target_game_card.reload.location).to eq 'hand'
    end

    it 'HPが最大値に戻る' do
      step.call(context)
      expect(target_game_card.reload.current_hp).to eq 5
    end

    it 'positionがnilになる' do
      step.call(context)
      expect(target_game_card.reload.position).to be_nil
    end

    context '手札が空の場合' do
      it 'position_in_stackが0になる' do
        step.call(context)
        expect(target_game_card.reload.position_in_stack).to eq 0
      end
    end

    context '手札に既にカードがある場合' do
      before do
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: target_card, location: :hand, position_in_stack: 0)
        create(:game_card, game: game, user: opponent_user, game_player: opponent,
               card: target_card, location: :hand, position_in_stack: 1)
      end

      it 'position_in_stackが手札の枚数と等しくなる' do
        step.call(context)
        expect(target_game_card.reload.position_in_stack).to eq 2
      end
    end

    context '付与されていたモディファイアがある場合' do
      before do
        target_game_card.modifiers.create!(effect_type: :stun, duration: 1, modification_type: :temporary)
        target_game_card.modifiers.create!(effect_type: :poison, value: 2, duration: 3, modification_type: :temporary)
      end

      it 'モディファイアが削除される' do
        expect { step.call(context) }.to change { target_game_card.modifiers.count }.to(0)
      end
    end

    context 'ターゲットがボードにいない場合' do
      before { target_game_card.update!(location: :hand) }

      it '何も起こらない' do
        expect { step.call(context) }.not_to raise_error
        expect(target_game_card.reload.location).to eq 'hand'
      end
    end

    context '処理中にエラーが発生した場合' do
      before do
        allow(target_game_card.modifiers).to receive(:destroy_all).and_raise(StandardError, "Error")
      end

      it 'エラーが発生し、ロールバックされる' do
        expect {
          step.call(context)
        }.to raise_error(StandardError, "Error")

        expect(target_game_card.reload.location).to eq "board"
      end
    end
  end
end
