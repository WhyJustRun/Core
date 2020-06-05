class RenameResultComment < ActiveRecord::Migration
  def change
    rename_column :results, :comment, :registrant_comment
  end
end
