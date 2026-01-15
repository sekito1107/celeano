require 'rails_helper'

RSpec.describe CardEffects::Steps::DestroyUnit, type: :model do
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

  let(:target_card) { create(:card, :unit) }
  let(:target_game_card) do
    create(:game_card, game: game, user: opponent_user, game_player: opponent,
           card: target_card, location: :board, position: :center, current_hp: 5)
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

    it 'ターゲットが墓地に移動する' do
      step.call(context)
      expect(target_game_card.reload.location).to eq 'graveyard'
    end

    it 'ターゲットのHPが0になる' do
      step.call(context)
      expect(target_game_card.reload.current_hp).to eq 0
    end

    context 'ターゲットが既に墓地にいる場合' do
      before { target_game_card.update!(location: :graveyard) }

      it '何も起こらない' do
        step.call(context)
        target_game_card.reload
        expect(target_game_card.location).to eq 'graveyard'
        expect(target_game_card.current_hp).to eq 5  # 元のHP値が維持される
      end
    end
  end
end
