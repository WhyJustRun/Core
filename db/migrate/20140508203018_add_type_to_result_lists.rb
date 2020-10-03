class AddTypeToResultLists < ActiveRecord::Migration[4.2]
  def change
    add_column :result_lists, :status, :string
  end
end
