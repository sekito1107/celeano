require 'rails_helper'

RSpec.describe CardEffects::Steps::DrawCards, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:turn) { create(:turn, game: game) }

  let(:spell_card) { create(:card, :spell) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: spell_card, location: :hand)
  end

  let(:unit_card) { create(:card, :unit) }

  # デッキにカードを配置
  let!(:deck_card1) do
    create(:game_card, game: game, user: user, game_player: player,
           card: unit_card, location: :deck, position_in_stack: 0)
  end
  let!(:deck_card2) do
    create(:game_card, game: game, user: user, game_player: player,
           card: unit_card, location: :deck, position_in_stack: 1)
  end
  let!(:deck_card3) do
    create(:game_card, game: game, user: user, game_player: player,
           card: unit_card, location: :deck, position_in_stack: 2)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: nil,
      timing: :on_play
    )
  end

  describe '#call' do
    context '2枚引く場合' do
      let(:step) { described_class.new(count: 2) }

      it '2枚が手札に移動する' do
        step.call(context)
        expect(deck_card1.reload.location).to eq 'hand'
        expect(deck_card2.reload.location).to eq 'hand'
        expect(deck_card3.reload.location).to eq 'deck'
      end

      it '手札のposition_in_stackが設定される' do
        step.call(context)
        expect(deck_card1.reload.position_in_stack).to eq 1
        expect(deck_card2.reload.position_in_stack).to eq 2
      end
    end

    context 'デッキにカードが足りない場合(デッキ枯渇テスト)' do
      before do
        deck_card2.destroy!
        deck_card3.destroy!
      end

      # デッキに1枚のみ残っている状態
      let(:step) { described_class.new(count: 2) }

      it 'デッキが空になるとdeck_deathでゲームが終了する' do
        # 1枚しかない状態で2枚引こうとすると、1枚引いた後にデッキ枯渇で死ぬ
        step.call(context)
        expect(deck_card1.reload.location).to eq 'hand'

        game.reload
        expect(game.finished?).to be true
        expect(game.finish_reason).to eq Game::FINISH_REASONS[:deck_death]
      end
    end
  end
end
