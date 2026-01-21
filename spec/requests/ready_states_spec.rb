require 'rails_helper'

RSpec.describe "ReadyStates", type: :request do
  let!(:player_user) { create(:user) }
  let!(:opponent_user) { create(:user) }
  let!(:game) { create(:game, :playing) }
  let!(:turn) { create(:turn, game: game, turn_number: 1) }

  let!(:player_gp) { create(:game_player, game: game, user: player_user, role: :host) }
  let!(:opponent_gp) { create(:game_player, game: game, user: opponent_user, role: :guest) }

  let(:result) { double(:result, success?: true, phase_completed: false, message: nil) }

  before do
    allow(ToggleReady).to receive(:call).and_return(result)
  end

  describe "POST /games/:game_id/ready_states" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        post game_ready_states_path(game)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン時" do
      before { sign_in player_user }

      context "正常系" do
        context "準備完了のみの場合（フェーズ完了ではない）" do
          it "準備完了メッセージと共にリダイレクトされること" do
            post game_ready_states_path(game)

            expect(ToggleReady).to have_received(:call).with(
              game_player: player_gp,
              turn: turn
            )
            expect(response).to redirect_to(game_path(game))
            expect(flash[:notice]).to eq("準備完了状態を変更しました")
          end

          # JSON test removed as JSON format is no longer supported

          it "Turbo Streamリクエストに対して成功レスポンスを返すこと" do
            post game_ready_states_path(game), as: :turbo_stream

            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include('<turbo-stream action="replace" target="player-status">')
            expect(flash.now[:notice]).to eq("準備完了状態を変更しました")
          end
        end

        context "両者が準備完了しフェーズが完了した場合" do
          let(:result) { double(:result, success?: true, phase_completed: true, message: nil) }

          it "ターン終了メッセージと共にリダイレクトされること" do
            post game_ready_states_path(game)

            expect(response).to redirect_to(game_path(game))
            expect(flash[:notice]).to eq("ターン終了")
          end

          # JSON test removed as JSON format is no longer supported
        end
      end

      context "異常系" do
        context "ToggleReady Interactorが失敗した場合" do
          let(:result) { double(:result, success?: false, message: "操作が許可されていません") }

          it "エラーメッセージと共にリダイレクトされること" do
            post game_ready_states_path(game)

            expect(response).to redirect_to(game_path(game))
            expect(flash[:alert]).to eq("操作が許可されていません")
          end

          # JSON test removed as JSON format is no longer supported
        end

        context "ゲームに参加していないユーザーの場合" do
          let(:other_user) { create(:user) }
          before { sign_in other_user }

          it "ロビーにリダイレクトされること" do
            post game_ready_states_path(game)
            expect(response).to redirect_to(lobby_path)
            expect(flash[:alert]).to eq("ゲームまたはプレイヤーが見つかりません")
          end
        end
      end
    end
  end
end
