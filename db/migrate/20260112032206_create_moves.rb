class CreateMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :moves do |t|
      t.references :turn, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :game_card, null: false, foreign_key: true

      t.integer :action_type, null: false

      t.integer :position

      t.references :target_game_card, null: true, foreign_key: { to_table: :game_cards }
      t.references :target_player, null: true, foreign_key: { to_table: :game_players }

      t.timestamps
    end
    add_index :moves, :action_type
  end
end
