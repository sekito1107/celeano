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
      elsif desc.include?("敵")
        "enemy_unit"
      else
        "any_unit"
      end
    elsif desc.include?("敵の全ユニット")
      "enemy_board"
    elsif desc.include?("自分の全ユニット")
      "ally_board"
    else
      "none"
    end
  end
  def resolved_image_path
    image_name = self.image_name.presence || resolve_fallback_image_name

    # PropshaftなどのDigest付きパスを解決して返す
    begin
      ActionController::Base.helpers.asset_path("cards/#{image_name}")
    rescue
      # 失敗時はフォールバック
      "/assets/cards/#{image_name}"
    end
  end

  private

  def resolve_fallback_image_name
    name_str = name || ""
    if spell?
      "art_ritual.png"
    elsif name_str.include?("ダゴン") || name_str.include?("深きもの")
      "art_dagon.png"
    elsif name_str.include?("信者")
      "art_cultist.png"
    elsif name_str.include?("ショゴス") || name_str.include?("ハイドラ") || name_str.include?("クトゥルフ")
      "art_shoggoth.png"
    else
      "art_cultist.png"
    end
  end
end
