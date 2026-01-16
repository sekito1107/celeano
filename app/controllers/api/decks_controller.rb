module Api
  class DecksController < ApplicationController
    allow_unauthenticated_access
    before_action :authenticate_with_session!

    def update
      if current_user.update(deck_params)
        render json: {
          status: "success",
          selected_deck: current_user.selected_deck,
          message: "Deck updated successfully"
        }
      else
        render json: {
          status: "error",
          errors: current_user.errors.full_messages
        }, status: :unprocessable_content
      end
    end

    private

    def deck_params
      params.require(:user).permit(:selected_deck)
    end

    # セッション認証を強制（APIだがCookieベース）
    def authenticate_with_session!
      unless authenticated?
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
