class CreateGamePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :game_players do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role
      t.integer :hp
      t.integer :san
      t.json :deck_data
      t.json :hand_data
      t.json :graveyard_data

      t.timestamps
    end
  end
end
