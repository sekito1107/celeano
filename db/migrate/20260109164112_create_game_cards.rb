class CreateGameCards < ActiveRecord::Migration[8.1]
  def change
    create_table :game_cards do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :position
      t.integer :current_hp
      t.integer :summoned_turn
      t.json :status_effects

      t.timestamps
    end
  end
end
