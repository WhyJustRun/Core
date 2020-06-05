class MoreDatabaseConstraintsForCrossAppSessions < ActiveRecord::Migration
  def up
    add_index :cross_app_sessions, :user_id, :unique => true
    add_index :cross_app_sessions, :cross_app_session_id, :unique => true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
