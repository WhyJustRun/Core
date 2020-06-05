class AddOrganizerCommentOnResult < ActiveRecord::Migration
  def change
    add_column :results, :official_comment, :string
  end
end
