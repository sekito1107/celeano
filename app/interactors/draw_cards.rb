# 両プレイヤーがカードを1枚ドローする
class DrawCards
  include Interactor

  def call
    game = context.game
    # ゲームが終了している場合は何もしない
    return if game.finished?

    game.game_players.order(:id).each do |player|
      player.draw_card!
      game.check_deck_death!(player)
      break if game.reload.finished?
    end
  end
end
