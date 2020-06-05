class RenameLiveResultsToResultLists < ActiveRecord::Migration
  def change
    rename_table :live_results, :result_lists
  end
end
