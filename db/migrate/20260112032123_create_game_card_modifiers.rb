class CreateGameCardModifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :game_card_modifiers do |t|
      t.references :game_card, null: false, foreign_key: true

      t.integer :modification_type, null: false
      t.integer :effect_type, null: false
      t.integer :value
      t.integer :duration
      t.string :source_name

      t.timestamps
    end
  end
end
