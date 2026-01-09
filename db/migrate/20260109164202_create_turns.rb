class CreateTurns < ActiveRecord::Migration[8.1]
  def change
    create_table :turns do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :turn_number
      t.integer :status

      t.timestamps
    end
  end
end
