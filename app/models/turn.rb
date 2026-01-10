class Turn < ApplicationRecord
  belongs_to :game
  has_many :moves, dependent: :destroy
  has_one :battle_log, dependent: :destroy

  enum :status, { planning: 0, resolving: 1, done: 2 }, default: :planning
end
