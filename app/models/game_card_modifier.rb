class GameCardModifier < ApplicationRecord
  belongs_to :game_card

  enum :effect_type, {
    poison: 0,       # 毒状態（毎ターン終了時ダメージ）
    stun: 1,         # スタン状態（次ターン行動不能）
    attack_buff: 2,  # 攻撃力増加を受けている
    hp_buff: 3       # HP増加を受けている
  }

  enum :modification_type, {
    temporary: 0,    # 一時的な効果（ターン経過で消える）
    permanent: 1     # 永続的な効果
  }

  validates :effect_type, presence: true
  validates :modification_type, presence: true
  validates :value, numericality: { only_integer: true }, allow_nil: true
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :duration, presence: true, if: :temporary?
  validates :duration, absence: true, if: :permanent?
end
