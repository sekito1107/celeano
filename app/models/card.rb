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

  def targeted?
    # Ensure boolean return
    !!description&.include?("対象")
  end

  def target_type
    return "slot" if unit?
    return "none" unless spell?

    desc = description || ""
    if desc.include?("対象")
      if desc.include?("味方")
        "ally_unit"
      # Default to enemy_unit if explicitly "enemy" or unsure (offensive spells)
      else
        "enemy_unit"
      end
    elsif desc.include?("敵の全ユニット")
      "enemy_board"
    elsif desc.include?("自分の全ユニット")
      "ally_board"
    else
      "none"
    end
  end
end
