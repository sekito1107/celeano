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

  def pending_cost_range_for(user)
    # user_idで検索するためにIDを取得
    user_id = user.is_a?(User) ? user.id : user

    pending_moves = moves.includes(game_card: :card).where(user_id: user_id)
    return [ 0, 0 ] if pending_moves.empty?

    min_total = 0
    max_total = 0

    pending_moves.each do |move|
      cost_str = move.game_card.card.cost
      min, max = Dice.range(cost_str)
      min_total += min
      max_total += max
    end

    [ min_total, max_total ]
  end
end
