class AddUpdatedAtToLiveResults < ActiveRecord::Migration[4.2]
  def change
    add_column :live_results, :updated_at, :datetime
  end
end
