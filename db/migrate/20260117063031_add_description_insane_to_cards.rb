class AddDescriptionInsaneToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :description_insane, :text
  end
end
