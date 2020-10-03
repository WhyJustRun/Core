class AddColorToMapStandards < ActiveRecord::Migration[4.2]
  def change
    add_column :map_standards, :color, :text, :limit => 255
  end
end
