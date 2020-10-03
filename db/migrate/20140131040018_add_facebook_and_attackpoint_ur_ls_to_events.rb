class AddFacebookAndAttackpointUrLsToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :facebook_url, :string
    add_column :events, :attackpoint_url, :string
  end
end
