# The app now uses the encrypted cookie session store instead of the database
# store (see config/initializers/session_store.rb), so the server-side sessions
# table is no longer used. Reversible: down recreates the table as it was.
class DropSessionsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :sessions if table_exists?(:sessions)
  end

  def down
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps null: false
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end
end
