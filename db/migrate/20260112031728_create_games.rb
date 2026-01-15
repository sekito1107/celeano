class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.integer :status, null: false, default: 0
      t.integer :seed, null: false

      t.string :finish_reason
      t.datetime :finished_at

      t.references :winner, foreign_key: { to_table: :users }
      t.references :loser, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
