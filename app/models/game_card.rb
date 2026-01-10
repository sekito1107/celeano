class GameCard < ApplicationRecord
  belongs_to :game
  belongs_to :user
  belongs_to :card

  enum :position, { left: 0, center: 1, right: 2 }, prefix: true
end
