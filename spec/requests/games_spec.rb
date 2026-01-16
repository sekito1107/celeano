require "rails_helper"

RSpec.describe "Games", type: :request do
  describe "GET /games/:id" do
    let(:game) { create(:game) }
    let(:user) { create(:user) }
    let!(:game_player) { create(:game_player, game: game, user: user) }

    context "when user is logged in" do
      before { sign_in(user) }

      context "when user is a participant" do
        it "returns http success" do
          get game_path(game)
          expect(response).to have_http_status(:success)
        end
      end

      context "when user is not a participant" do
        let(:other_game) { create(:game) }

        it "redirects to root path with alert" do
          get game_path(other_game)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq("このゲームに参加する権限がありません。")
        end
      end

      context "when game does not exist" do
        it "redirects to root path with alert" do
          get game_path(id: 0)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq("指定されたゲームは見つかりませんでした。")
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login page" do
        get game_path(game)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
