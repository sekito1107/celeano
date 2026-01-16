module Lobby
  class GameModeCardComponent < ViewComponent::Base
    def initialize(title:, description:, image_path:, action_text:, badge: "CASUAL", url: nil)
      @title = title
      @description = description
      @image_path = image_path
      @action_text = action_text
      @badge = badge
      @url = url
    end

    private

    attr_reader :title, :description, :image_path, :action_text, :badge, :url
  end
end
