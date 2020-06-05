class EvenMoreDatabaseConstraintsForCrossAppSessions < ActiveRecord::Migration
  def up
    change_table(:cross_app_sessions) do |t|
      t.change :user_id, :integer, :null => false
      t.change :cross_app_session_id, :string, :null => false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
