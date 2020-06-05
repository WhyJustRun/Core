class GetRidOfSessionIdFromCrossAppSession < ActiveRecord::Migration
  def change
    remove_column :cross_app_sessions, :session_id, :string
  end
end
