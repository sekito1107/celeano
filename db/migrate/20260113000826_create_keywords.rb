class CreateKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :keywords do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :keywords, :name, unique: true
  end
end
