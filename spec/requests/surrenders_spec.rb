require "rails_helper"

RSpec.describe "Surrenders", type: :request do
  let!(:user) { create(:user) }
  let!(:opponent) { create(:user) }
  let!(:game) { create(:game, status: :playing) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }
  # roles 'host' / 'guest' に修正
  let!(:game_player) { create(:game_player, game: game, user: user, role: :host) }
  let!(:opponent_player) { create(:game_player, game: game, user: opponent, role: :guest) }

  describe "POST /games/:game_id/surrender" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        post game_surrender_path(game)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン時" do
      before { sign_in(user) }

      context "正常系" do
        it "降伏が成功し、ゲーム画面へリダイレクトされること" do
          expect {
            post game_surrender_path(game)
          }.to change { game.reload.status }.from("playing").to("finished")

          expect(response).to redirect_to(game_path(game))
          expect(flash[:notice]).to eq("降伏しました。")
        end

        it "JSONリクエストに対して成功レスポンスを返すこと" do
          post game_surrender_path(game), as: :json
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("降伏しました。")
        end

        context "既に終了しているゲームの場合" do
          let(:finished_game) { create(:game, status: :finished) }
          let(:finished_gp) { create(:game_player, game: finished_game, user: user, role: :host) }
          let(:finished_turn) { create(:turn, game: finished_game, turn_number: 1) }

          it "エラーにならず、降伏完了メッセージが表示されること" do
            # game_context_loaderがデータを取得できるようにデータ作成
            finished_gp
            finished_turn

            post game_surrender_path(finished_game)

            expect(response).to redirect_to(game_path(finished_game))
            expect(flash[:notice]).to eq("ゲームは既に終了しています。")
            # ステータスはfinishedのまま変わらない
            expect(finished_game.reload.status).to eq("finished")
          end
        end
      end

      context "異常系" do
        context "参加していないゲームの場合" do
          let(:other_game) { create(:game) }

          it "ロビーにリダイレクトされ、エラーが表示されること" do
            post game_surrender_path(other_game)
            expect(response).to redirect_to(lobby_path)
            expect(flash[:alert]).to eq("ゲームまたはプレイヤーが見つかりません")
          end

          it "JSONリクエストの場合、404エラーが返ること" do
            post game_surrender_path(other_game), as: :json
            expect(response).to have_http_status(:not_found)
          end
        end

        context "存在しないゲームIDの場合" do
          it "ロビーにリダイレクトされ、エラーが表示されること" do
            post game_surrender_path("invalid_id")
            expect(response).to redirect_to(lobby_path)
            expect(flash[:alert]).to eq("ゲームまたはプレイヤーが見つかりません")
          end
        end
      end
    end
  end
end
