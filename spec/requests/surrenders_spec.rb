require "rails_helper"

RSpec.describe "Surrenders", type: :request do
  describe "POST /games/:game_id/surrender" do
    let(:user) { create(:user) }
    let(:game) { create(:game, status: :playing) }
    let!(:game_player) { create(:game_player, game: game, user: user) }
    let!(:opponent_player) { create(:game_player, game: game) }
    let!(:turn) { create(:turn, game: game) }

    before do
      sign_in(user)
    end

    context "when user is a participant" do
      it "ends the game for the player and redirects to lobby" do
        expect {
          post game_surrender_path(game)
        }.to change { game.reload.status }.from("playing").to("finished")

        expect(response).to redirect_to(lobby_path)
        expect(flash[:notice]).to eq("降伏しました。")
      end
    end

    context "when user is NOT a participant" do
      let(:other_game) { create(:game) }

      it "does not effect the game and redirects to lobby with alert" do
        post game_surrender_path(other_game)

        expect(response).to redirect_to(lobby_path)
        expect(flash[:alert]).to eq("ゲームに参加していません。")
      end
    end
  end
end
