class RenameResultComment < ActiveRecord::Migration[4.2]
  def change
    rename_column :results, :comment, :registrant_comment
  end
end
