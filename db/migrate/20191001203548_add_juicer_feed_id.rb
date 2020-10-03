class AddJuicerFeedId < ActiveRecord::Migration[4.2]
  def change
    add_column :clubs, :juicer_feed_id, :string
  end
end
