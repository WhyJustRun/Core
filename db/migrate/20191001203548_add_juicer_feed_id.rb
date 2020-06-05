class AddJuicerFeedId < ActiveRecord::Migration
  def change
    add_column :clubs, :juicer_feed_id, :string
  end
end
