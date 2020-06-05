class RemoveUnusedDescriptionColumnFromSeries < ActiveRecord::Migration
  def up
    remove_column :series, :description
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
