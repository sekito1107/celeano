# ダメージ計算と適用を行うPORO
class DamageCalculator
  def initialize(game)
    @game = game
    @nonce_offset = Move.joins(:turn).where(turns: { game_id: game.id }).count
  end

  def calculate_attack_power(attacker, index = 0)
    base_damage = Dice.roll(attacker.current_attack.to_s, game.seed, nonce_offset + index)
    buff = attacker.attack_buff_value
    base_damage + buff
  end

  private

  attr_reader :game, :nonce_offset
end
