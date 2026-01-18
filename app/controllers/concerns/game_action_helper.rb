module GameActionHelper
  extend ActiveSupport::Concern

  private

  def handle_game_action(result, success_message: nil)
    if result.success?
      message = success_message || result.message

      respond_to do |format|
        format.html { redirect_to game_path(@game), notice: message }
        format.json { render json: { status: "success", message: message }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to game_path(@game), alert: result.message }
        format.json { render json: { status: "error", message: result.message }, status: :unprocessable_content }
      end
    end
  end
end
