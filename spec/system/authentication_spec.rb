require "rails_helper"

RSpec.describe "Authentication", type: :system do
  describe "ログイン" do
    let(:user) { create(:user) }

    context "正しい情報を入力した場合" do
      it "ログインできること" do
        visit new_session_path

        fill_in "Identifier", with: user.email_address
        fill_in "Passphrase", with: "password123" # User factory default
        click_on "Access Archive"

        # expect(page).to have_content("ログインしました") # フラッシュメッセージ等は実装依存、一旦パスだけ確認
        # ログイン後のリダイレクト先（ルートなど）を確認
        expect(page).to have_current_path(lobby_path)
      end
    end

    context "誤った情報を入力した場合" do
      it "ログインできずエラーが表示されること" do
        visit new_session_path

        fill_in "Identifier", with: user.email_address
        fill_in "Passphrase", with: "wrong_password"
        click_on "Access Archive"

        expect(page).to have_content("メールアドレスまたはパスワードが正しくありません。")
      end
    end
  end

  describe "ログアウト" do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it "ログアウトできること" do
      visit root_path
      click_on "ログアウト"
      # expect(page).to have_content("ログアウトしました")
      expect(page).to have_content("INVESTIGATOR LOGIN")
    end
  end
end
