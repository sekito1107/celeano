require 'rails_helper'

RSpec.describe "Lobbies", type: :request do
  let(:user) { create(:user) }

  describe "GET /lobby" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get lobby_path
        expect(response).to have_http_status(:success)
      end

      it "displays the user profile" do
        get lobby_path
        expect(response.body).to include(user.name)
      end

      it "displays the forbidden library mode" do
        get lobby_path
        expect(response.body).to include("禁断の書庫")
      end
    end

    context "when not authenticated" do
      it "redirects to login path" do
        get lobby_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
