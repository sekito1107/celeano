class ResolveDamage
  include Interactor

  def call
    return if context.game.finished?

    attack_plan = context.attack_plan
    game = context.game
    calculator = DamageCalculator.new(game)

    damage_results = build_damage_results(attack_plan, calculator)
    apply_all_damage(damage_results)

    context.damage_results = damage_results
  end

  private

  def build_damage_results(attack_plan, calculator)
    attack_plan.each_with_index.map do |attack, index|
      attacker = attack[:attacker]
      damage = calculator.calculate_attack_power(attacker, index)
      {
        attacker: attacker,
        target: attack[:target],
        target_type: attack[:target_type],
        damage: damage
      }
    end
  end

  def apply_all_damage(damage_results)
    ActiveRecord::Base.transaction do
      damage_results.each do |result|
        break if context.game.reload.finished?

        attacker = result[:attacker]
        target = result[:target]
        damage = result[:damage]
        target_type = result[:target_type]

        target_info = target_type == :player ?
          { target_type: "player", target_player_id: target.id } :
          { target_type: "unit", target_card_id: target.id, target_card_name: target.card.name }

        attacker.log_event!(:attack, {
          attacker_id: attacker.id,
          attacker_name: attacker.card.name,
          damage: damage
        }.merge(target_info))

        target.take_damage!(damage)
        context.game.check_player_death!(target) if target.is_a?(GamePlayer)
      end
    end
  end
end
