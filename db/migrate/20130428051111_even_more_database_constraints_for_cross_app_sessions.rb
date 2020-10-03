class EvenMoreDatabaseConstraintsForCrossAppSessions < ActiveRecord::Migration[4.2]
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
