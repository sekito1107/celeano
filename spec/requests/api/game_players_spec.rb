require 'rails_helper'

RSpec.describe "Api::GamePlayers", type: :request do
  describe "PUT /api/games/:game_id/players/:id/deck" do
    let(:game) { create(:game, status: :matching) }
    let(:game_player) { create(:game_player, game: game) }
    let(:other_game) { create(:game, status: :matching) }
    let(:other_game_player) { create(:game_player, game: other_game) }

    context "正しいゲームのプレイヤーにアクセスした場合" do
      before do
        sign_in_as(game_player.user)
      end

      it "デッキが正常に更新されること" do
        put "/api/games/#{game.id}/players/#{game_player.id}/deck", params: { game_player: { deck_type: 'custom_deck' } }
        expect(response).to have_http_status(:ok)
        expect(game_player.reload.deck_type).to eq('custom_deck')
      end
    end

    context "異なるゲームのプレイヤーにアクセスした場合" do
      before do
        sign_in_as(game_player.user)
      end

      it "404 Not Foundを返すこと" do
        put "/api/games/#{game.id}/players/#{other_game_player.id}/deck", params: { game_player: { deck_type: 'hacked_deck' } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "権限のないユーザーがアクセスした場合" do
      before do
        sign_in_as(other_game_player.user)
      end

      it "404 Not Foundを返すこと" do
        put "/api/games/#{game.id}/players/#{game_player.id}/deck", params: { game_player: { deck_type: 'custom_deck' } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ゲームが既に開始されている場合" do
      let(:started_game) { create(:game, status: :playing) }
      let(:started_game_player) { create(:game_player, game: started_game) }

      before do
        sign_in_as(started_game_player.user)
      end

      it "422 Unprocessable Entityを返すこと" do
        put "/api/games/#{started_game.id}/players/#{started_game_player.id}/deck", params: { game_player: { deck_type: 'custom_deck' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to eq("Cannot change deck after game started")
      end
    end
  end
end
