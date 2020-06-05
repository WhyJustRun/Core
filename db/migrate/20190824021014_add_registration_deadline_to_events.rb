class AddRegistrationDeadlineToEvents < ActiveRecord::Migration
  def change
    add_column :events, :registration_deadline, :datetime
  end
end
