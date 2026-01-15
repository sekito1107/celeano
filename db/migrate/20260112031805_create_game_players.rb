class CreateGamePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :game_players do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.integer :role, null: false, default: 0
      t.integer :hp, null: false, default: 20
      t.integer :san, null: false, default: 20
      t.boolean :ready, default: false, null: false

      t.timestamps
    end
    add_index :game_players, [ :game_id, :user_id ], unique: true
  end
end
