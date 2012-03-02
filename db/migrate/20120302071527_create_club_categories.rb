class CreateClubCategories < ActiveRecord::Migration
  def change
    create_table :club_categories do |t|

      t.timestamps
    end
  end
end
