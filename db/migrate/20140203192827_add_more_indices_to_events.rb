class AddMoreIndicesToEvents < ActiveRecord::Migration[4.2]
  def change
    add_index :events, [:lat, :lng]
    add_index :events, :lat
    add_index :events, :lng
    add_index :events, :date
    add_index :events, :finish_date
    add_index :events, [:results_posted, :results_url]
  end
end
