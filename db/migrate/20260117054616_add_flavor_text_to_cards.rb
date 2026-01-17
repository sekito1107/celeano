class AddFlavorTextToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :flavor_text, :text
  end
end
