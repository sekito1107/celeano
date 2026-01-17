class AddThresholdToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :threshold, :integer
  end
end
