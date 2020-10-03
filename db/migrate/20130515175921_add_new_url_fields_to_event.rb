class AddNewUrlFieldsToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :results_url, :string
    add_column :events, :registration_url, :string
    add_column :events, :routegadget_url, :string
  end
end
