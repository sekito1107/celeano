class CreateMatchmakingQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :matchmaking_queues do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :deck_type, null: false

      t.timestamps
    end
  end
end
