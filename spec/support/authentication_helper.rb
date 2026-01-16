module AuthenticationHelper
  # Systemスペック用: UI経由でログインする
  def login_as(user, password: "password123")
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: password
    click_on "ログイン"
    expect(page).to have_content("ログインしました")
  end
end
