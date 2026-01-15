class CreateGameCards < ActiveRecord::Migration[8.1]
  def change
    create_table :game_cards do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.references :game_player, null: false, foreign_key: true

      t.integer :location, null: false, default: 0
      t.integer :position_in_stack
      t.integer :position

      t.integer :current_hp, null: false
      t.string :current_attack, null: false, default: "0"
      t.integer :summoned_turn

      t.timestamps
    end

    add_index :game_cards, [ :game_id, :user_id, :location ]
    add_index :game_cards, [ :game_id, :user_id, :location, :position_in_stack ]
    add_index :game_cards, [ :game_player_id, :location ]
  end
end
