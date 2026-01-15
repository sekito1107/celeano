class CreateTurns < ActiveRecord::Migration[8.1]
  def change
    create_table :turns do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :turn_number, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :turns, [ :game_id, :turn_number ], unique: true
  end
end
