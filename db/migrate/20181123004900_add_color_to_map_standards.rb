class AddColorToMapStandards < ActiveRecord::Migration
  def change
    add_column :map_standards, :color, :text, :limit => 255
  end
end
