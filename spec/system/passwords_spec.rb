require "rails_helper"

RSpec.describe "パスワードリセット", type: :system do
  let!(:user) { create(:user) }

  describe "リセット申請" do
    it "申請を送信できる" do
      # 直接パスワードリセット申請ページにアクセス
      visit new_password_path

      # ページが正しく表示されていることを確認
      expect(page).to have_css(".auth-form__title")

      # メールアドレスを入力して送信
      fill_in "email_address", with: user.email_address
      click_button "Send Recovery Sigil"

      # ログインページにリダイレクトされ、フラッシュメッセージが表示される
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("パスワードリセットの手順を送信しました")
    end
  end

  describe "パスワード更新" do
    it "新しいパスワードを設定できる" do
      # トークンを生成してパスワード更新ページにアクセス
      token = user.generate_token_for(:password_reset)
      visit edit_password_path(token: token)

      # ページが正しく表示されていることを確認
      expect(page).to have_css(".auth-form__title")

      # 新しいパスワードを入力して送信
      fill_in "password", with: "new_secure_password123"
      fill_in "password_confirmation", with: "new_secure_password123"
      click_button "Update Credentials"

      # ログインページにリダイレクトされる
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("パスワードが更新されました")
    end
  end
end
