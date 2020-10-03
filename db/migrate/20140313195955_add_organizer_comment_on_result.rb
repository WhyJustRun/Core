class AddOrganizerCommentOnResult < ActiveRecord::Migration[4.2]
  def change
    add_column :results, :official_comment, :string
  end
end
