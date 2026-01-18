require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "ランディングページが正しく表示されること" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CALL OF")
      expect(response.body).to include("CELAENO")
      expect(response.body).to include("プレアデス星団の彼方へ")
      expect(response.body).to include('href="/assets/home') # Verifies stylesheet link
    end

    it "未認証でもアクセスできること" do
      # Ensure no redirect to login
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
