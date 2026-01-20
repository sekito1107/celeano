class ResolveDamage
  include Interactor

  def call
    return if context.game.finished?

    attack_plan = context.attack_plan
    game = context.game
    calculator = DamageCalculator.new(game)

    ActiveRecord::Base.transaction do
      # Phase 1: 攻撃時効果の発動（バフ等）
      trigger_attack_effects(attack_plan)

      # Phase 2: ダメージ計算（バフ適用後の状態で計算）
      damage_results = build_damage_results(attack_plan, calculator)

      # Phase 3: ダメージ適用
      apply_all_damage(damage_results)

      context.damage_results = damage_results
    end
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

  def trigger_attack_effects(attack_plan)
    attack_plan.each do |attack|
      attacker = attack[:attacker]
      target = attack[:target]
      attacker.trigger(:on_attack, target)
    end
  end


  def apply_all_damage(damage_results)
    damage_results.each do |result|
      break if context.game.reload.finished?
      apply_single_attack(result)
    end
  end

  def apply_single_attack(result)
    attacker = result[:attacker]
    target = result[:target]
    damage = result[:damage]
    target_type = result[:target_type]

    target.take_damage!(damage)
    target.reload # 最新のステータス再取得

    # ターゲット情報の再構築（ダメージ適用後のHPなどを含めるため）
    target_info = build_target_info(target, target_type)

    attacker.log_event!(:attack, {
      attacker_id: attacker.id,
      attacker_name: attacker.card.name,
      attacker_position: attacker.position,
      attacker_player_id: attacker.game_player_id,
      damage: damage
    }.merge(target_info))

    context.game.check_player_death!(target) if target.is_a?(GamePlayer)
  end

  def build_target_info(target, target_type)
    if target_type == :player
      {
        target_type: "player",
        target_player_id: target.id,
        target_hp: target.hp,
        target_san: target.san
      }
    else
      {
        target_type: "unit",
        target_card_id: target.id,
        target_card_name: target.card.name,
        target_hp: target.current_hp
      }
    end
  end
end
