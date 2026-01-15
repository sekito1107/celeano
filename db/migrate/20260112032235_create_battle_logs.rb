class CreateBattleLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :battle_logs do |t|
      t.references :turn, null: false, foreign_key: true

      t.string :event_type, null: false, index: true
      t.json :details, default: {}, null: false

      t.timestamps
    end
  end
end
