class GameCard < ApplicationRecord
  belongs_to :game
  belongs_to :user
  belongs_to :card
end
