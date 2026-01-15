module AuthenticationHelper
  # リクエストスペック用: セッションにuser_idを設定してログイン状態にする
  def sign_in_as(user)
    post api_sessions_path, params: { name: user.name }
  end

  # ログアウト
  def sign_out
    delete api_sessions_path
  end
end
