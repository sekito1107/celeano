class AddSelectedDeckToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :selected_deck, :string, default: "cthulhu", null: false
  end
end
