class PayResolvePhaseCosts
  include Interactor

  def call
    game = context.game
    return if game.finished?

    turn = game.turns.find_by(turn_number: game.current_turn_number)
    return unless turn

    # このターンにプレイされたカード（Move）を取得
    moves = turn.moves.includes(game_card: :card).includes(:user)

    if context.target_card_types
      moves = moves.select { |m| context.target_card_types.include?(m.game_card.card.card_type.to_sym) }
    end

    # プレイヤーごとにコストを計算して消費
    moves.group_by(&:user).each do |user, user_moves|
      game_player = game.game_players.find_by(user: user)
      next unless game_player

      total_cost = user_moves.sum { |m| m.cost || 0 }

      if total_cost > 0
        game_player.pay_cost!(total_cost)
        game.check_player_death!(game_player)
      end
    end
  end
end
