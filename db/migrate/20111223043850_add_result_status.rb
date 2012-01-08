class AddResultStatus < ActiveRecord::Migration
  def change
	  add_column :results, :status, :string
  end
end
