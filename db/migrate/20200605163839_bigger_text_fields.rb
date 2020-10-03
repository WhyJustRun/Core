class BiggerTextFields < ActiveRecord::Migration[4.2]
  def change
    change_column :pages, :content, :mediumtext
    change_column :events, :description, :mediumtext
    change_column :maps, :notes, :mediumtext
    change_column :courses, :description, :mediumtext
    change_column :clubs, :description, :mediumtext
    change_column :content_blocks, :content, :mediumtext
    change_column :event_classifications, :description, :mediumtext
    change_column :groups, :description, :mediumtext
    change_column :map_standards, :description, :mediumtext
    change_column :roles, :description, :mediumtext
    change_column :series, :information, :mediumtext
  end
end

