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

      # Phase 4: 死亡判定（相打ちチェック）
      process_deaths(game)

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
      # ゲーム終了済みなら即中断（防御的チェック：即死効果等の将来拡張に備える）
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

    # NOTE: 個別の死亡判定は行わず、最後に一括で行うため check_player_death! は呼び出さない
  end

  def process_deaths(game)
    return if game.reload.finished?

    dead_players = game.game_players.select { |p| p.hp <= 0 }

    if dead_players.any?
      if dead_players.size >= 2
        # HP Draw (Mutual Destruction)
        game.finish_draw!(Game::FINISH_REASONS[:hp_draw])
      else
        # Normal HP Death
        dead_players.each do |player|
          game.check_player_death!(player)
          break if game.finished? # 一人が死んだら終了（現在は1vs1前提）
        end
      end
    end
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
