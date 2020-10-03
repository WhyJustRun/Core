class AddDeviseToUsers < ActiveRecord::Migration[4.2]
  def self.up
     
    # Deactivate users with duplicate email addresses
    # NOTE: You only need to run this stuff if you have pre-existing users in your db
    
    emails = User.select("count(email) as email_count, email, id").group("email")
    emails.each { |email| 
      if (email.email_count > 1) then
        p email
        p email.email
        users = User.where("email = ?", email.email).order("id ASC").offset(1)
        # Deactivate all except the first user..
        users.each { |user|
          p user.name
          user.email = nil
          if (user.save) then
            p "Email saving win"
          end

        }
      end
    } 

   # Schema changes
    change_table(:users) do |t|
      ## Database authenticatable
      t.change :email, :string
      t.rename :password, :old_password
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Token authenticatable
      # t.string :authentication_token


      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps
    end
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
