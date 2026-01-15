class AddDeckTypeToGamePlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :game_players, :deck_type, :string
  end
end
