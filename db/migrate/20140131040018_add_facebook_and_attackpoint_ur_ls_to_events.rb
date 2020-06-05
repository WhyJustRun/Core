class AddFacebookAndAttackpointUrLsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :facebook_url, :string
    add_column :events, :attackpoint_url, :string
  end
end
