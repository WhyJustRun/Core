class AddModificationTimeFieldsToResources < ActiveRecord::Migration
  def change
    add_column :resources, :updated_at, :datetime
    add_column :resources, :created_at, :datetime
  end
end
