class RemoveCourseAndMapFromResourcesTable < ActiveRecord::Migration
  def change
    # not ever used
    remove_reference :resources, :course
    remove_reference :resources, :map
  end
end
