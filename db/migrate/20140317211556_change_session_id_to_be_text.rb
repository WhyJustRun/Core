class ChangeSessionIdToBeText < ActiveRecord::Migration
  def change
    change_column :cross_app_sessions, :session_id, :string
  end
end
