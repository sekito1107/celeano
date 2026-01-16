class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      flash.keep
      redirect_to lobby_path
    end
  end
end
