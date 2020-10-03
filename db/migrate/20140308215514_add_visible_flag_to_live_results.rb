class AddVisibleFlagToLiveResults < ActiveRecord::Migration[4.2]
  def change
    add_column :live_results, :visible, :boolean, default: 0, null: false
  end
end
