# 手札が7枚を超える場合、超えた分を墓地に捨てる
class EnforceHandLimit
  include Interactor

  HAND_LIMIT = 7

  def call
    game = context.game
    # ゲームが終了している場合は何もしない
    return if game.finished?

    game.game_players.each do |player|
      enforce_limit_for(player)
    end
  end

  private

  def enforce_limit_for(player)
    hand = player.hand.to_a
    excess_count = hand.size - HAND_LIMIT

    return unless excess_count > 0

    # 手札の末尾から超過分を捨てる（最後に引いたカードから）
    cards_to_discard = hand.last(excess_count)

    ActiveRecord::Base.transaction do
      cards_to_discard.each do |game_card|
        player.discard_card!(game_card, reason: :hand_limit)
      end
    end
  end
end
