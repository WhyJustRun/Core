class CreateShortLinks < ActiveRecord::Migration
  def change
    create_table :short_links do |t|
      t.string :name
      t.string :destination
    end
    add_index(:short_links, :name, unique: true)
  end
end
