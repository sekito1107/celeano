class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.string :name, null: false
      t.string :key_code, null: false

      t.integer :card_type, null: false, default: 0
      t.string :cost, null: false, default: "0"
      t.string :attack, null: false, default: "0"
      t.integer :hp, null: false, default: 0
      t.integer :threshold_san, default: 0, null: false

      t.text :description
      t.string :image_name

      t.timestamps
    end
    add_index :cards, :key_code, unique: true
  end
end
