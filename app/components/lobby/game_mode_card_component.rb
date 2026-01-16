module Lobby
  class GameModeCardComponent < ViewComponent::Base
    def initialize(title:, description:, image_path:, action_text:)
      @title = title
      @description = description
      @image_path = image_path
      @action_text = action_text
    end

    private

    attr_reader :title, :description, :image_path, :action_text
  end
end
