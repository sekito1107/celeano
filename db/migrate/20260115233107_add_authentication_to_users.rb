class AddAuthenticationToUsers < ActiveRecord::Migration[8.1]
  def change
    # メールアドレス（ログインID）
    add_column :users, :email_address, :string, null: false, default: ""
    add_index :users, :email_address, unique: true

    # パスワードハッシュ (bcrypt)
    add_column :users, :password_digest, :string, null: false, default: ""
  end
end
