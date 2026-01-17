class RemoveThresholdFromCards < ActiveRecord::Migration[8.1]
  def change
    remove_column :cards, :threshold, :integer
  end
end
