class DetermineAttackTargets
  include Interactor

  def call
    game = context.game
    attack_plan = []

    players = game.game_players.to_a
    players.each do |attacker_player|
      opponent = players.find { |p| p.id != attacker_player.id }
      next unless opponent

      attackers = attacker_player.game_cards.includes(:card, :modifiers).where(location: :board)

      attackers.each do |attacker|
        next unless attacker.can_attack?

        resolver = TargetResolver.new(attacker, opponent)
        attack_plan << {
          attacker: attacker,
          target: resolver.resolve,
          target_type: resolver.target_type
        }
      end
    end

    context.attack_plan = attack_plan
  end
end
