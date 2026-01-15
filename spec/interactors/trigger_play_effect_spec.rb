require 'rails_helper'

RSpec.describe TriggerPlayEffect, type: :interactor do
  describe '.call' do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let(:game_player) { create(:game_player, game: game, user: user) }
    let(:target) { create(:game_card, game: game) }

    let(:card) { create(:card, :unit) }
    let(:game_card) { create(:game_card, game: game, game_player: game_player, card: card) }

    let(:context_params) do
      {
        game_card: game_card,
        target: target
      }
    end

    context '効果(:on_play)を持っている場合' do
      before do
        allow(game_card).to receive(:has_effect?).with(:on_play).and_return(true)
      end

      it 'triggerメソッドが実行されること' do
        expect(game_card).to receive(:trigger).with(:on_play, target)

        result = described_class.call(context_params)
        expect(result).to be_a_success
      end
    end

    context '効果(:on_play)を持っていない場合' do
      before do
        allow(game_card).to receive(:has_effect?).with(:on_play).and_return(false)
      end

      it 'triggerメソッドは実行されないこと' do
        expect(game_card).not_to receive(:trigger)

        result = described_class.call(context_params)
        expect(result).to be_a_success
      end
    end
  end
end
