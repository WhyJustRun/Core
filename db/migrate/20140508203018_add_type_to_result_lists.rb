class AddTypeToResultLists < ActiveRecord::Migration
  def change
    add_column :result_lists, :status, :string
  end
end
