class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.integer :status
      t.integer :turn_count
      t.string :finish_reason
      t.datetime :finished_at
      t.references :winner, null: true, foreign_key: { to_table: :users }
      t.references :loser, null: true, foreign_key: { to_table: :users }
      t.integer :seed

      t.timestamps
    end
  end
end
