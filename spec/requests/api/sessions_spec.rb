# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Sessions", type: :request do
  describe "POST /api/sessions" do
    context "新規ユーザーの場合" do
      it "ユーザーを作成してログインする" do
        expect {
          post api_sessions_path, params: { name: "新規プレイヤー" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]["name"]).to eq("新規プレイヤー")
      end
    end

    context "既存ユーザーの場合" do
      let!(:existing_user) { create(:user, name: "既存プレイヤー") }

      it "既存ユーザーとしてログインする" do
        expect {
          post api_sessions_path, params: { name: "既存プレイヤー" }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]["id"]).to eq(existing_user.id)
        expect(response.parsed_body["user"]["name"]).to eq("既存プレイヤー")
      end
    end

    context "名前が空の場合" do
      it "エラーを返す" do
        post api_sessions_path, params: { name: "" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["error"]).to eq("名前を入力してください")
      end
    end

    context "名前がnilの場合" do
      it "エラーを返す" do
        post api_sessions_path, params: {}

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /api/sessions" do
    let!(:user) { create(:user, name: "テストユーザー") }

    before do
      post api_sessions_path, params: { name: user.name }
    end

    it "ログアウトする" do
      delete api_sessions_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("ログアウトしました")
    end
  end

  describe "GET /api/sessions/current" do
    context "ログイン済みの場合" do
      let!(:user) { create(:user, name: "ログイン中ユーザー") }

      before do
        post api_sessions_path, params: { name: user.name }
      end

      it "現在のユーザー情報を返す" do
        get current_api_sessions_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]["id"]).to eq(user.id)
        expect(response.parsed_body["user"]["name"]).to eq("ログイン中ユーザー")
      end
    end

    context "未ログインの場合" do
      it "user: nilを返す" do
        get current_api_sessions_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]).to be_nil
      end
    end
  end
end
