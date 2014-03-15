class SupportBothFacebookAndGoogleAccounts < ActiveRecord::Migration
  def up
    add_column :users, :google_id, :string
    add_column :users, :facebook_id, :string

    User.find_each { |user|
      if user.provider == 'google_oauth2'
        user.google_id = user.uid
      elsif user.provider == 'facebook'
        user.facebook_id = user.uid
      end
      user.save
    }

    remove_column :users, :provider
    remove_column :users, :uid
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
