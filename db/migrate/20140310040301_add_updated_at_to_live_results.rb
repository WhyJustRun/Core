class AddUpdatedAtToLiveResults < ActiveRecord::Migration
  def change
    add_column :live_results, :updated_at, :datetime
  end
end
