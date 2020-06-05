class AddNotesToMaps < ActiveRecord::Migration
  def change
    add_column :maps, :notes, :text
  end
end
