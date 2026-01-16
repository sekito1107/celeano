module AuthenticationHelper
  # Systemスペック用: UI経由でログインする
  def login_as(user, password: "password123")
    visit new_session_path
    fill_in "Identifier", with: user.email_address
    fill_in "Passphrase", with: password
    click_on "Access Archive"
    expect(page).to have_content("ログインしました")
  end

  # Requestスペック用: セッションを作成する
  def sign_in(user, password: "password123")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end
