class CreateCardKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :card_keywords do |t|
      t.references :card, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true

      t.timestamps
    end

    add_index :card_keywords, [ :card_id, :keyword_id ], unique: true
  end
end
