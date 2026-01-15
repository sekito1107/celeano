class Card < ApplicationRecord
  has_many :game_cards, dependent: :destroy
  has_many :card_keywords, dependent: :destroy
  has_many :keywords, through: :card_keywords

  enum :card_type, { unit: 0, spell: 1 }

  validates :name, presence: true
  validates :key_code, presence: true, uniqueness: true

  KEYWORDS = {
    haste: "haste",
    guardian: "guardian"
  }.freeze

  def has_keyword?(keyword_name)
    if association(:keywords).loaded?
      keywords.any? { |k| k.name == keyword_name }
    else
      keywords.exists?(name: keyword_name)
    end
  end

  def haste?
    has_keyword?(KEYWORDS[:haste])
  end

  def guardian?
    has_keyword?(KEYWORDS[:guardian])
  end
end
