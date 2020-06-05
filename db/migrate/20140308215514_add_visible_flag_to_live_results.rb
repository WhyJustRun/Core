class AddVisibleFlagToLiveResults < ActiveRecord::Migration
  def change
    add_column :live_results, :visible, :boolean, default: 0, null: false
  end
end
