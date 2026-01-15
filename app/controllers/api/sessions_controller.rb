# frozen_string_literal: true

module Api
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /api/sessions
    # 名前でログイン（存在しなければ新規作成）
    def create
      name = params[:name]&.strip

      if name.blank?
        render json: { error: "名前を入力してください" }, status: :unprocessable_content
        return
      end

      user = User.find_or_create_by!(name: name)
      session[:user_id] = user.id

      render json: { user: { id: user.id, name: user.name } }, status: :ok
    end

    # DELETE /api/sessions
    # ログアウト
    def destroy
      session.delete(:user_id)
      render json: { message: "ログアウトしました" }, status: :ok
    end

    # GET /api/sessions/current
    # 現在のログイン状態を取得
    def current
      if current_user
        render json: { user: { id: current_user.id, name: current_user.name } }, status: :ok
      else
        render json: { user: nil }, status: :ok
      end
    end
  end
end
