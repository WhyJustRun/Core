class SwitchToRegistrationComments < ActiveRecord::Migration[4.2]
  def up
    add_column :results, :comment, :string

    Result.all.each { |result|
      if (result.needs_ride == true)
        say "Needs ride"
        result.comment = "Need a ride"
        result.save
      elsif (result.offering_ride == true)
        result.comment = "Offering ride"
        result.save
      end
    }

    remove_column :results, :needs_ride
    remove_column :results, :offering_ride
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
