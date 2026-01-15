class PayCost
  include Interactor

  def call
    return if context.game.finished?

    context.game_player.pay_cost!(context.paid_cost)
    context.game.check_player_death!(context.game_player)
  end
end
