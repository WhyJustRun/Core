class RemoveUrlsFromResourcesTable < ActiveRecord::Migration[4.2]
  def change
    columns = %i(url thumbnail_50_url thumbnail_100_url thumbnail_500_url thumbnail_1000_url thumbnail_1300_url thumbnail_2600_url)
    columns.each { |column|
      remove_column :resources, column, :string
    }
  end
end
