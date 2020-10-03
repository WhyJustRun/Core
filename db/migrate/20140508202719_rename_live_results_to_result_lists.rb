class RenameLiveResultsToResultLists < ActiveRecord::Migration[4.2]
  def change
    rename_table :live_results, :result_lists
  end
end
