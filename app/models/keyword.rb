class Keyword < ApplicationRecord
  has_many :card_keywords, dependent: :destroy
  has_many :cards, through: :card_keywords

  validates :name, presence: true, uniqueness: true
end
