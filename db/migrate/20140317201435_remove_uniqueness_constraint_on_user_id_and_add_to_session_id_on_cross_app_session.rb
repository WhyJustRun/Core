class RemoveUniquenessConstraintOnUserIdAndAddToSessionIdOnCrossAppSession < ActiveRecord::Migration
  def change
    remove_index :cross_app_sessions, column: :user_id, unique: true
    add_index :cross_app_sessions, :user_id, unique: false
    
    remove_index :cross_app_sessions, column: :session_id, unique: false
    add_index :cross_app_sessions, :session_id, unique: true
  end
end
