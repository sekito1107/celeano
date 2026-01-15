module Loggable
  extend ActiveSupport::Concern

  def log_event!(event_type, details = {})
    BattleLog.create!(
      turn: active_turn,
      event_type: event_type.to_s,
      details: enrich_details(details)
    )
  end

  private

  def active_turn
    resolve_game.turns.order(:turn_number).last
  end

  def enrich_details(original_details)
    original_details.merge({
      source_class: self.class.name,
      source_id: self.id,
      timestamp: Time.current.iso8601
    })
  end

  def resolve_game
    self.is_a?(Game) ? self : game
  end
end
