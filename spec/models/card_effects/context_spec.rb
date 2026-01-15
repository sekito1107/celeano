require 'rails_helper'

RSpec.describe CardEffects::Context, type: :model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user, role: :host, san: 15) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user, role: :guest, san: 20) }

  let(:card) { create(:card, :unit, key_code: "test_unit", threshold_san: 10) }
  let(:game_card) do
    create(:game_card, game: game, user: user, game_player: player,
           card: card, location: :board, position: :center)
  end

  let(:target_card) { create(:card, :unit) }
  let(:target_game_card) do
    create(:game_card, game: game, user: opponent_user, game_player: opponent,
           card: target_card, location: :board, position: :center)
  end

  let(:context) do
    CardEffects::Context.new(
      source_card: game_card,
      target: target_game_card,
      timing: :on_play
    )
  end

  describe '#initialize' do
    it 'source_cardを保持する' do
      expect(context.source_card).to eq game_card
    end

    it 'targetを保持する' do
      expect(context.target).to eq target_game_card
    end

    it 'timingを保持する' do
      expect(context.timing).to eq :on_play
    end

    it 'gameを取得できる' do
      expect(context.game).to eq game
    end

    it 'game_playerを取得できる' do
      expect(context.game_player).to eq player
    end
  end

  describe '#insane?' do
    context 'SANが閾値以下の場合' do
      before { player.update!(san: 10) }

      it 'trueを返す' do
        expect(context.insane?).to be true
      end
    end

    context 'SANが閾値より大きい場合' do
      before { player.update!(san: 15) }

      it 'falseを返す' do
        expect(context.insane?).to be false
      end
    end

    context '閾値が0の場合' do
      let(:card) { create(:card, :unit, key_code: "no_threshold", threshold_san: 0) }

      it 'falseを返す' do
        expect(context.insane?).to be false
      end
    end
  end

  describe '#enemy_player' do
    it '対戦相手のプレイヤーを返す' do
      expect(context.enemy_player).to eq opponent
    end
  end

  describe '#enemy_board_units' do
    let!(:enemy_unit) do
      create(:game_card, game: game, user: opponent_user, game_player: opponent,
             card: target_card, location: :board, position: :left)
    end
    let!(:ally_unit) do
      create(:game_card, game: game, user: user, game_player: player,
             card: card, location: :board, position: :right)
    end

    it '敵のボード上のユニットのみを返す' do
      enemy_units = context.enemy_board_units
      expect(enemy_units).to include(target_game_card, enemy_unit)
      expect(enemy_units).not_to include(game_card, ally_unit)
    end
  end

  describe '#ally_board_units' do
    let!(:enemy_unit) do
      create(:game_card, game: game, user: opponent_user, game_player: opponent,
             card: target_card, location: :board, position: :left)
    end
    let!(:ally_unit) do
      create(:game_card, game: game, user: user, game_player: player,
             card: card, location: :board, position: :right)
    end

    it '味方のボード上のユニットのみを返す' do
      ally_units = context.ally_board_units
      expect(ally_units).to include(game_card, ally_unit)
      expect(ally_units).not_to include(target_game_card, enemy_unit)
    end
  end

  describe '#log_effect' do
    it 'source_cardのlog_event!を呼び出す' do
      expect(game_card).to receive(:log_event!).with(
        :damage_dealt,
        hash_including(
          card_name: card.name,
          key_code: card.key_code,
          timing: :on_play,
          amount: 5
        )
      )

      context.log_effect(:damage_dealt, amount: 5)
    end

    it 'detailsなしでも動作する' do
      expect(game_card).to receive(:log_event!).with(
        :effect_triggered,
        hash_including(
          card_name: card.name,
          key_code: card.key_code,
          timing: :on_play
        )
      )

      context.log_effect(:effect_triggered)
    end
  end
end
