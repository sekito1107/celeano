require 'rails_helper'

RSpec.describe Game, type: :model do
  describe '#finish_game!' do
    let(:game) { create(:game, status: :playing) }
    let!(:turn) { create(:turn, game: game, turn_number: 1) }

    let(:winner_user) { create(:user) }
    let(:loser_user) { create(:user) }

    let!(:winner) { create(:game_player, game: game, user: winner_user) }
    let!(:loser) { create(:game_player, game: game, user: loser_user) }

    context 'SAN値切れ(SAN_DEATH)で終了する場合' do
      let(:reason) { "SAN_DEATH" }

      it 'ステータス更新とログ出力が正常に行われること' do
        expect {
          game.finish_game!(loser, reason)
        }.to change(BattleLog, :count).by(1)

        expect(game).to be_finished
        expect(game.finish_reason).to eq "SAN_DEATH"
        expect(game.loser).to eq loser_user
        expect(game.winner).to eq winner_user
        expect(game.finished_at).to be_present

        log = BattleLog.last
        expect(log.event_type).to eq 'game_finish'
        expect(log.details['reason']).to eq 'SAN_DEATH'
        expect(log.details['loser_player_id']).to eq loser.user_id
        expect(log.details['winner_player_id']).to eq winner.user_id
      end
    end

    context 'HP切れ(HP_DEATH)で終了する場合' do
      let(:reason) { "HP_DEATH" }

      it 'ログを残して正常に終了すること' do
        expect {
          game.finish_game!(loser, reason)
        }.to change(BattleLog, :count).by(1)

        expect(game.finish_reason).to eq "HP_DEATH"
        expect(game).to be_finished
      end
    end

    context 'デッキ切れ(DECK_DEATH)で終了する場合' do
      let(:reason) { "DECK_DEATH" }

      it 'ログを残して正常に終了すること' do
        expect {
          game.finish_game!(loser, reason)
        }.to change(BattleLog, :count).by(1)

        expect(game.finish_reason).to eq "DECK_DEATH"
        expect(game).to be_finished
      end
    end
  end

  describe '#check_player_death!' do
    let(:game) { create(:game, status: :playing) }
    let!(:turn) { create(:turn, game: game, turn_number: 1) }
    let!(:player) { create(:game_player, game: game, hp: 10, san: 10) }
    let!(:opponent) { create(:game_player, game: game) }

    context 'SAN値が0の場合' do
      before { player.update!(san: 0) }

      it 'SAN_DEATHでゲームが終了する' do
        game.check_player_death!(player)

        expect(game.reload).to be_finished
        expect(game.finish_reason).to eq 'SAN_DEATH'
        expect(game.loser).to eq player.user
      end
    end

    context 'HP値が0の場合' do
      before { player.update!(hp: 0) }

      it 'HP_DEATHでゲームが終了する' do
        game.check_player_death!(player)

        expect(game.reload).to be_finished
        expect(game.finish_reason).to eq 'HP_DEATH'
        expect(game.loser).to eq player.user
      end
    end

    context 'SAN/HP両方が残っている場合' do
      it 'ゲームは終了しない' do
        game.check_player_death!(player)

        expect(game.reload).not_to be_finished
      end
    end

    context 'ゲームが既に終了している場合' do
      before { game.update!(status: :finished) }

      it '何も起こらない' do
        expect { game.check_player_death!(player) }.not_to change { game.reload.attributes }
      end
    end
  end

  describe '#check_deck_death!' do
    let(:game) { create(:game, status: :playing) }
    let!(:turn) { create(:turn, game: game, turn_number: 1) }
    let(:user) { create(:user) }
    let!(:player) { create(:game_player, game: game, user: user) }
    let!(:opponent) { create(:game_player, game: game) }
    let(:card) { create(:card) }

    context 'デッキが空の場合' do
      it 'DECK_DEATHでゲームが終了する' do
        expect {
          game.check_deck_death!(player)
        }.to change(BattleLog, :count).by(2) # deck_empty + game_finish

        expect(game.reload).to be_finished
        expect(game.finish_reason).to eq 'DECK_DEATH'
        expect(game.loser).to eq user
      end
    end

    context 'デッキにカードがある場合' do
      before do
        create(:game_card, game: game, game_player: player, user: user, card: card, location: :deck)
      end

      it 'ゲームは終了しない' do
        game.check_deck_death!(player)

        expect(game.reload).not_to be_finished
      end
    end

    context 'ゲームが既に終了している場合' do
      before { game.update!(status: :finished) }

      it '何も起こらない' do
        expect { game.check_deck_death!(player) }.not_to change { game.reload.attributes }
      end
    end
  end
end
