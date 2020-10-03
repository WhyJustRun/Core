class RemoveCourseAndMapFromResourcesTable < ActiveRecord::Migration[4.2]
  def change
    # not ever used
    remove_reference :resources, :course
    remove_reference :resources, :map
  end
end
