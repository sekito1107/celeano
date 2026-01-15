class Turn < ApplicationRecord
  belongs_to :game
  has_many :moves, dependent: :destroy
  has_many :battle_logs, dependent: :destroy

  enum :status, { planning: 0, resolving: 1, done: 2 }, default: :planning

  SUMMON_LIMITS = {
    1..2 => 1,
    3..4 => 2
  }.freeze
  DEFAULT_SUMMON_LIMIT = 3

  def unit_summon_limit
    SUMMON_LIMITS.find { |range, _| range.cover?(turn_number) }&.last || DEFAULT_SUMMON_LIMIT
  end

  def units_summoned_count(user)
    moves.where(user: user)
         .joins(game_card: :card)
         .merge(Card.unit)
         .count
  end

  def summon_limit_reached?(user)
    units_summoned_count(user) >= unit_summon_limit
  end
end
