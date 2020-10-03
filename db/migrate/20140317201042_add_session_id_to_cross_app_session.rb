class AddSessionIdToCrossAppSession < ActiveRecord::Migration[4.2]
  def change
    add_reference :cross_app_sessions, :session, index: true
  end
end
