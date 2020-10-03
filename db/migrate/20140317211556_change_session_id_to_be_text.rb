class ChangeSessionIdToBeText < ActiveRecord::Migration[4.2]
  def change
    change_column :cross_app_sessions, :session_id, :string
  end
end
