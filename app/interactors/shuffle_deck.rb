# デッキをシャッフルする
# position_in_stackをランダムに再割り当て
class ShuffleDeck
  include Interactor

  def call
    game = context.game

    ActiveRecord::Base.transaction do
      game.game_players.each do |player|
        shuffle_player_deck(player, game)
      end
    end
  end

  private

  def shuffle_player_deck(player, game)
    deck_cards = player.deck.to_a
    return if deck_cards.empty?

    # シャッフル（ゲームのseedを使用して再現可能にする）
    shuffled = deck_cards.shuffle(random: Random.new(game.seed + player.id))

    # SQLインジェクションを防ぐためにsanitize_sql_arrayを使用
    cases = []
    args = []
    shuffled.each_with_index do |card, index|
      cases << "WHEN ? THEN ?"
      args << card.id
      args << index
    end



    sql = "position_in_stack = CASE id #{cases.join(' ')} END"
    sanitized_sql = GameCard.sanitize_sql_array([ sql, *args ])

    GameCard.where(id: shuffled.map(&:id)).update_all(sanitized_sql)
  end
end
