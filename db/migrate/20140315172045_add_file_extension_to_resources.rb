class AddFileExtensionToResources < ActiveRecord::Migration[4.2]
  def up
    add_column :resources, :extension, :string 

    Resource.find_each { |resource|
      resource.extension = resource.url.split('.')[-1]
      resource.save
    }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
