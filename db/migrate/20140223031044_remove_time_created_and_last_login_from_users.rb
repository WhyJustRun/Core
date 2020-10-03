class RemoveTimeCreatedAndLastLoginFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :last_login, :datetime
    remove_column :users, :time_created, :datetime
  end
end
