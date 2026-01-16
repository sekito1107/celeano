# frozen_string_literal: true

class FlashComponent < ApplicationComponent
  def initialize(flash: {})
    @flash = flash || {}
  end

  def alerts
    Array(@flash[:alert])
  end

  def notices
    Array(@flash[:notice])
  end

  def render?
    alerts.any? || notices.any?
  end
end
