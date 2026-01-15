require 'rails_helper'

RSpec.describe ProcessCardMovement, type: :interactor do
  describe '.call' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let(:game_player) { create(:game_player, game: game, user: user) }

    let(:context_params) do
      {
        game_card: game_card,
        position: 'center'
      }
    end

    context 'ユニットカードの場合' do
      let(:unit_card) { create(:card, :unit) }
      let(:game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: unit_card, location: :hand) }

      it '予約状態(resolving)に移動すること' do
        result = described_class.call(context_params)

        expect(result).to be_a_success
        expect(game_card.location).to eq 'resolving'
        expect(game_card.position).to eq 'center'
      end

      it 'summoned_turnはまだ設定されないこと' do
        described_class.call(context_params)

        expect(game_card.summoned_turn).to be_nil
      end
    end

    context 'positionが指定されていない場合（ユニットカード）' do
      let(:unit_card) { create(:card, :unit) }
      let(:game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: unit_card, location: :hand) }
      let(:context_params_invalid) { { game_card: game_card, position: nil } }

      it '失敗すること' do
        result = described_class.call(context_params_invalid)
        expect(result).to be_a_failure
        expect(result.message).to eq 'Position is required for unit'
      end
    end

    context 'スペルカードの場合' do
      let(:spell_card) { create(:card, :spell) }
      let(:game_card) { create(:game_card, game: game, user: user, game_player: game_player, card: spell_card, location: :hand) }

      it '予約状態(resolving)に移動すること' do
        result = described_class.call(context_params)

        expect(result).to be_a_success
        expect(game_card.location).to eq 'resolving'
      end

      it 'スペルカードはpositionが設定されないこと' do
        described_class.call(context_params)

        expect(game_card.position).to be_nil
      end
    end
  end
end
