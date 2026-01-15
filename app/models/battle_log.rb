class BattleLog < ApplicationRecord
  belongs_to :turn
  has_one :game, through: :turn

  validates :event_type, presence: true
end
