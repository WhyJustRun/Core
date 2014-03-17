class AddSessionIdToCrossAppSession < ActiveRecord::Migration
  def change
    add_reference :cross_app_sessions, :session, index: true
  end
end
