require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#join_matchmaking!' do
    let(:user) { create(:user) }
    let(:deck_type) { 'cthulhu' }

    before do
      allow(StartGame).to receive(:call)
    end

    context '対戦相手が待っていない場合' do
      it '待機キューを作成すること' do
        expect {
          user.join_matchmaking!(deck_type)
        }.to change(MatchmakingQueue, :count).by(1)

        queue = MatchmakingQueue.last
        expect(queue.user).to eq(user)
        expect(queue.deck_type).to eq(deck_type)
      end

      it 'nilを返すこと' do
        expect(user.join_matchmaking!(deck_type)).to be_nil
      end

      it '既に待機中の場合、既存のキューを更新すること' do
        user.join_matchmaking!('hastur')
        previous_queue = user.matchmaking_queue

        expect {
          user.join_matchmaking!(deck_type)
        }.not_to change(MatchmakingQueue, :count)

        user.reload
        expect(user.matchmaking_queue.deck_type).to eq(deck_type)
        expect(user.matchmaking_queue.id).not_to eq(previous_queue.id) # Recreated
      end
    end

    context '対戦相手が待っている場合' do
      let(:opponent) { create(:user) }
      let!(:opponent_queue) { create(:matchmaking_queue, user: opponent, deck_type: 'hastur') }

      it 'ゲームを作成すること' do
        expect {
          user.join_matchmaking!(deck_type)
        }.to change(Game, :count).by(1)
      end

      it '両方のユーザーのゲームプレイヤーを作成すること' do
        user.join_matchmaking!(deck_type)
        game = Game.last

        expect(game.users).to include(user, opponent)
        expect(game.game_players.find_by(user: user).role).to eq('host')
        expect(game.game_players.find_by(user: opponent).role).to eq('guest')
      end

      it '対戦相手をキューから削除すること' do
        expect {
          user.join_matchmaking!(deck_type)
        }.to change(MatchmakingQueue, :count).by(-1)

        expect(MatchmakingQueue.exists?(id: opponent_queue.id)).to be_falsey
      end

      it 'StartGameを呼び出すこと' do
        expect(StartGame).to receive(:call).with(game: kind_of(Game))
        user.join_matchmaking!(deck_type)
      end

      it '作成されたゲームを返すこと' do
        result = user.join_matchmaking!(deck_type)
        expect(result).to be_a(Game)
        expect(result.status).to eq('playing')
      end

      it '自分自身をキューに追加しないこと' do
        user.join_matchmaking!(deck_type)
        expect(user.matchmaking_queue).to be_nil
      end
    end
  end

  describe '#leave_matchmaking!' do
    let(:user) { create(:user) }

    context 'キューにいる場合' do
      before { user.join_matchmaking!('cthulhu') }

      it 'キューから削除すること' do
        expect {
          user.leave_matchmaking!
        }.to change(MatchmakingQueue, :count).by(-1)
      end
    end

    context 'キューにいない場合' do
      it '何もしないこと' do
        expect {
          user.leave_matchmaking!
        }.not_to change(MatchmakingQueue, :count)
      end
    end
  end
end
