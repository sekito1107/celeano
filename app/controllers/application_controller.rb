class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Rails 8 Authentication pattern: Current.session.userを使用
  # allow_unauthenticated_accessなアクションでもcurrent_userを正しく取得するため、
  # resume_sessionを呼び出す（冪等なので安全）
  def current_user
    resume_session
    Current.session&.user
  end
  helper_method :current_user
end
