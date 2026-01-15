require 'rails_helper'

RSpec.describe DrawCards, type: :interactor do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:opponent_user) { create(:user) }
  let!(:player) { create(:game_player, game: game, user: user) }
  let!(:opponent) { create(:game_player, game: game, user: opponent_user) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let(:unit_card) { create(:card, :unit) }

  describe '#call' do
    context '両プレイヤーにデッキがある場合' do
      before do
        # プレイヤー1のデッキ
        3.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :deck, position_in_stack: i)
        end
        # プレイヤー2のデッキ
        3.times do |i|
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: unit_card, location: :deck, position_in_stack: i)
        end
      end

      it '両プレイヤーがカードを1枚引く' do
        expect {
          described_class.call(game: game)
        }.to change { player.hand.count }.by(1)
          .and change { opponent.hand.count }.by(1)
      end

      it 'デッキが1枚ずつ減る' do
        expect {
          described_class.call(game: game)
        }.to change { player.deck.count }.by(-1)
          .and change { opponent.deck.count }.by(-1)
      end

      it 'ドローのBattleLogが作成される' do
        expect {
          described_class.call(game: game)
        }.to change { BattleLog.where(event_type: "draw").count }.by(2)
      end
    end

    context 'デッキが空のプレイヤーがいる場合' do
      before do
        # プレイヤー2だけデッキがある
        3.times do |i|
          create(:game_card, game: game, user: opponent_user, game_player: opponent,
                 card: unit_card, location: :deck, position_in_stack: i)
        end
      end

      it 'デッキ切れでゲームが終了する' do
        first_player = game.game_players.order(:id).first
        described_class.call(game: game)

        game.reload
        expect(game.status).to eq "finished"
        expect(game.finish_reason).to eq "DECK_DEATH"
        expect(game.loser_id).to eq first_player.user_id
      end
    end

    context 'ゲームが既に終了している場合' do
      before do
        game.update!(status: :finished)
        # プレイヤー1のデッキ
        3.times do |i|
          create(:game_card, game: game, user: user, game_player: player,
                 card: unit_card, location: :deck, position_in_stack: i)
        end
      end

      it '何も処理しない' do
        expect {
          described_class.call(game: game)
        }.not_to change { player.hand.count }
      end
    end

    context '両プレイヤーのデッキが空の場合' do
      it '最初のプレイヤーの敗北でゲームが終了し、上書きされない' do
        # 最初のプレイヤーを特定
        first_player = game.game_players.order(:id).first

        described_class.call(game: game)

        game.reload
        expect(game.status).to eq "finished"
        expect(game.finish_reason).to eq "DECK_DEATH"
        # 最初のプレイヤーの敗北でゲームが終了し、以降の処理は中断される
        expect(game.loser_id).to eq first_player.user_id
      end
    end
  end
end
