require 'rails_helper'

RSpec.describe "CardPlays", type: :request do
  let!(:player_user) { create(:user) }
  let!(:opponent_user) { create(:user) }
  let!(:game) { create(:game, :playing) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  # プレイヤーのゲームプレイヤー
  let!(:player_gp) { create(:game_player, game: game, user: player_user, role: :host) }
  # 相手のゲームプレイヤー
  let!(:opponent_gp) { create(:game_player, game: game, user: opponent_user, role: :guest) }

  # カードプレイ用のデータ
  let!(:card) { create(:card, cost: 1, card_type: :unit) }
  let!(:game_card) { create(:game_card, game: game, game_player: player_gp, card: card, location: :hand) }

  # Interactorのモック準備
  let(:result) { double(:result, success?: true, message: nil) }

  before do
    allow(PlayCard).to receive(:call).and_return(result)
  end

  describe "POST /games/:game_id/card_plays" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン時" do
      before { sign_in player_user }

      context "正常系" do
        it "カードプレイが成功し、リダイレクトされること" do
          post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }

          expect(PlayCard).to have_received(:call).with(
            game: game,
            turn: turn,
            game_player: player_gp,
            game_card: game_card,
            position: "1",
            target_id: nil
          )
          expect(response).to redirect_to(game_path(game))
          expect(flash[:notice]).to eq("カードをプレイしました")
        end

        it "JSONリクエストに対して成功レスポンスを返すこと" do
          post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }, as: :json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["status"]).to eq("success")
        end
      end

      context "異常系" do
        context "PlayCard Interactorが失敗した場合" do
          let(:result) { double(:result, success?: false, message: "コストが不足しています") }

          it "エラーメッセージと共にリダイレクトされること" do
            post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }

            expect(response).to redirect_to(game_path(game))
            expect(flash[:alert]).to eq("コストが不足しています")
          end

          it "JSONリクエストに対してエラーレスポンスを返すこと" do
            post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }, as: :json

            expect(response).to have_http_status(:unprocessable_content)
            json = JSON.parse(response.body)
            expect(json["status"]).to eq("error")
            expect(json["message"]).to eq("コストが不足しています")
          end
        end

        context "ゲームに参加していないユーザーの場合" do
          let(:other_user) { create(:user) }
          before { sign_in other_user }

          it "ロビーにリダイレクトされること" do
            post game_card_plays_path(game), params: { game_card_id: game_card.id, position: 1 }
            expect(response).to redirect_to(lobby_path)
            expect(flash[:alert]).to eq("ゲームまたはプレイヤーが見つかりません")
          end
        end

        context "存在しないゲームIDの場合" do
          it "ロビーにリダイレクトされること" do
            post game_card_plays_path("invalid_id"), params: { game_card_id: game_card.id, position: 1 }
            expect(response).to redirect_to(lobby_path)
            expect(flash[:alert]).to eq("ゲームまたはプレイヤーが見つかりません")
          end
        end
      end
    end
  end
  describe "DELETE /games/:game_id/card_plays/:game_card_id" do
    let!(:move) { create(:move, turn: turn, user: player_user, game_card: game_card, cost: 1) }

    context "未ログインの場合" do
      it "認証エラーを返すこと" do
        delete destroy_game_card_plays_path(game, game_card.id), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "ログイン時" do
      before { sign_in player_user }

      context "正常系" do
        it "JSONリクエストに対して成功レスポンスを返すこと" do
          expect {
            delete destroy_game_card_plays_path(game, game_card.id), as: :json
          }.to change(Move, :count).by(-1)

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["status"]).to eq("success")
          expect(JSON.parse(response.body)["message"]).to eq("アクションをキャンセルしました")
        end
      end

      context "異常系" do
        context "CancelCardPlay Interactorが失敗した場合" do
          before do
            allow(CancelCardPlay).to receive(:call).and_return(double(success?: false, message: "キャンセルできません"))
          end

          it "エラーレスポンスを返すこと" do
            delete destroy_game_card_plays_path(game, game_card.id), as: :json

            expect(response).to have_http_status(:unprocessable_content)
            expect(JSON.parse(response.body)["status"]).to eq("error")
            expect(JSON.parse(response.body)["message"]).to eq("キャンセルできません")
          end
        end
      end
    end
  end
end
