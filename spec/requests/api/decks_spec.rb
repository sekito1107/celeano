require 'rails_helper'

RSpec.describe "Api::Decks", type: :request do
  let(:user) { create(:user) }

  before do
    post session_path, params: { email_address: user.email_address, password: user.password }
  end

  describe "PATCH /api/deck" do
    context "有効なパラメータの場合" do
      it "選択されたデッキを更新すること" do
        patch api_deck_path, params: { user: { selected_deck: "hastur" } }
        expect(response).to have_http_status(:success)
        expect(user.reload.selected_deck).to eq("hastur")
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("success")
      end
    end

    context "無効なパラメータの場合" do
      before { user.update!(selected_deck: "cthulhu") }

      it "無効な値ではデッキを更新しないこと" do
        patch api_deck_path, params: { user: { selected_deck: "invalid_deck" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.selected_deck).to eq("cthulhu") # Default
      end
    end

    context "未認証の場合" do
      before { delete session_path }

      it "未認証ステータスを返すこと" do
        patch api_deck_path, params: { user: { selected_deck: "hastur" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
