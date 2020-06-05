class RemovePointsFromResults < ActiveRecord::Migration
  def change
    remove_column :results, :points, :integer
  end
end
