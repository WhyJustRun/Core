class RemoveUnusedTables < ActiveRecord::Migration
  def up
    drop_table :tokens
    drop_table :configuration
    drop_table :schema
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
