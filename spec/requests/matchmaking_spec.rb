require 'rails_helper'

RSpec.describe "Matchmaking", type: :request do
  describe "POST /matchmaking" do
    let(:user) { create(:user, selected_deck: "cthulhu") }

    before do
      allow(StartGame).to receive(:call!)
      post session_path, params: { email_address: user.email_address, password: user.password }
    end

    context "when opponent is not found" do
      it "redirects to the waiting screen" do
        expect {
          post matchmaking_path
        }.to change(MatchmakingQueue, :count).by(1)

        expect(response).to redirect_to(matchmaking_path)
      end
    end

    context "when opponent is found" do
      let(:opponent) { create(:user) }
      let!(:opponent_queue) { create(:matchmaking_queue, user: opponent, deck_type: "hastur") }

      it "redirects to the game screen" do
        expect {
          post matchmaking_path
        }.to change(Game, :count).by(1)

        game = Game.last
        expect(response).to redirect_to(game_path(game))
      end
    end
  end

  describe "GET /matchmaking" do
    let(:user) { create(:user) }

    before do
      post session_path, params: { email_address: user.email_address, password: user.password }
    end

    it "renders the waiting screen" do
      get matchmaking_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("対戦相手を探しています")
    end
  end
end
