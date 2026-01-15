# 攻撃対象を決定するPORO
# 優先順位: 1.正面の敵 → 2.守護持ち → 3.相手プレイヤー
class TargetResolver
  GUARDIAN_KEYWORD = Card::KEYWORDS[:guardian]

  def initialize(attacker, opponent)
    @attacker = attacker
    @opponent = opponent
  end

  def resolve
    @resolved_target ||= (front_enemy || guardian || player)
  end

  def target_type
    resolve.is_a?(GamePlayer) ? :player : :unit
  end

  private

  attr_reader :attacker, :opponent

  def front_enemy
    opponent.game_cards.includes(:card)
            .where(location: :board, position: attacker.position)
            .where("current_hp > 0")
            .first
  end

  def guardian
    guardians = opponent.game_cards.joins(card: :keywords)
                        .includes(:card)
                        .where(location: :board, keywords: { name: GUARDIAN_KEYWORD })
                        .where("current_hp > 0")
    guardians.order(current_hp: :desc, position: :asc).first
  end

  def player
    opponent
  end
end
