class AddTargetGameCardIdToGameCards < ActiveRecord::Migration[8.1]
  def change
    add_reference :game_cards, :target_game_card, null: true, foreign_key: { to_table: :game_cards }
  end
end
