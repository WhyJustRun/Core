# Cross-app sessions handed a signed-in user to the old CakePHP club sites.
# Club sites are served by this app now and sign in through the SSO tokens in
# SsoToken, so the table is unused. Reversible: down recreates it as it was.
class DropCrossAppSessions < ActiveRecord::Migration[7.2]
  def up
    drop_table :cross_app_sessions if table_exists?(:cross_app_sessions)
  end

  def down
    create_table :cross_app_sessions, id: :integer, charset: 'utf8mb3', collation: 'utf8mb3_general_ci' do |t|
      t.integer :user_id, null: false
      t.string :cross_app_session_id, null: false
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.index :cross_app_session_id, unique: true
      t.index :user_id
    end
  end
end
