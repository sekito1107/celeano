class Card < ApplicationRecord
  enum :card_type, { unit: 0, spell: 1 }

  has_many :game_cards
  has_many :moves

  validates :name, presence: true
  validates :cost, presence: true
end
