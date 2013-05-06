class CreateCrossAppSessions < ActiveRecord::Migration
  def change
    create_table :cross_app_sessions do |t|
      t.integer :user_id
      t.string :cross_app_session_id

      t.timestamps
    end
  end
end
