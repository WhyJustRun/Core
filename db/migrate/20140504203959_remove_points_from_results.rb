class RemovePointsFromResults < ActiveRecord::Migration[4.2]
  def change
    remove_column :results, :points, :integer
  end
end
