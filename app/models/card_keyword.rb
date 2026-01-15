class CardKeyword < ApplicationRecord
  belongs_to :card
  belongs_to :keyword

  validates :keyword_id, uniqueness: { scope: :card_id }
end
