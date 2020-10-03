class AddNotesToMaps < ActiveRecord::Migration[4.2]
  def change
    add_column :maps, :notes, :text
  end
end
