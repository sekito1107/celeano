module Matchmaking
  class PlayerCardComponent < ViewComponent::Base
    def initialize(name:, title:, status:, type: :user, image_path: nil)
      @name = name
      @title = title
      @status = status
      @type = type
      @image_path = image_path
    end

    private

    attr_reader :name, :title, :status, :type, :image_path

    def card_classes
      "player-card player-card--#{type}"
    end

    def status_classes
      case status
      when :ready
        "player-card__status player-card__status--ready"
      when :connecting
        "player-card__status player-card__status--connecting"
      end
    end

    def status_text
      case status
      when :ready
        "Ready"
      when :connecting
        "Connecting"
      end
    end

    def status_indicator
      case status
      when :ready
        tag.span(class: "status-dot")
      when :connecting
        tag.span(class: "status-spinner")
      end
    end
  end
end
