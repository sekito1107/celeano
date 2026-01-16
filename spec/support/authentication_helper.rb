module AuthenticationHelper
  # Systemスペック用: UI経由でログインする
  def login_as(user, password: "password123")
    visit new_session_path
    fill_in "Identifier", with: user.email_address
    fill_in "Passphrase", with: password
    click_on "Access Archive"
    expect(page).to have_content("ログインしました")
  end
end
