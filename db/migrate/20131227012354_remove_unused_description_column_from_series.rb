class RemoveUnusedDescriptionColumnFromSeries < ActiveRecord::Migration[4.2]
  def up
    remove_column :series, :description
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
