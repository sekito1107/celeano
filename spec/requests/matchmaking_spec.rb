require 'rails_helper'

RSpec.describe "マッチメイキング機能", type: :request do
  describe "POST /matchmaking (参加)" do
    let(:user) { create(:user, selected_deck: "cthulhu") }

    before do
      allow(StartGame).to receive(:call!)
      post session_path, params: { email_address: user.email_address, password: user.password }
    end

    context "対戦相手が見つからない場合" do
      it "待機画面にリダイレクトすること" do
        expect {
          post matchmaking_path
        }.to change(MatchmakingQueue, :count).by(1)

        expect(response).to redirect_to(matchmaking_path)
      end
    end

    context "対戦相手が見つかった場合" do
      let(:opponent) { create(:user) }
      let!(:opponent_queue) { create(:matchmaking_queue, user: opponent, deck_type: "hastur") }

      it "ゲーム画面にリダイレクトすること" do
        expect {
          post matchmaking_path
        }.to change(Game, :count).by(1)

        game = Game.last
        expect(response).to redirect_to(game_path(game))
      end
    end
  end

  describe "GET /matchmaking (待機画面)" do
    let(:user) { create(:user) }

    before do
      post session_path, params: { email_address: user.email_address, password: user.password }
    end

    it "待機画面を表示すること" do
      get matchmaking_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("探索中")
    end
  end

  describe "DELETE /matchmaking (キャンセル)" do
    let(:user) { create(:user) }

    before do
      post session_path, params: { email_address: user.email_address, password: user.password }
      user.join_matchmaking!("cthulhu")
    end

    it "キューからユーザーを削除し、ロビーにリダイレクトすること" do
      expect {
        delete matchmaking_path
      }.to change(MatchmakingQueue, :count).by(-1)

      expect(response).to redirect_to(lobby_path)
    end
  end
end
