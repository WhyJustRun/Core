class AddLiveResults < ActiveRecord::Migration[4.2]
  def change
    create_table :live_results do |t|
      t.text :data, :limit => 16777215 #medium text field
      t.references :event
      t.references :user
      t.datetime :upload_time
    end
    add_index :live_results, :event_id
    add_index :live_results, :upload_time
    add_index :live_results, :user_id
  end
end
