class AddEventMarkdown < ActiveRecord::Migration
  def change
	  add_column :events, :rendered_description, :text
	  Event.all.each { |e| e.update_attributes!(:rendered_description => Markdownizer.markdown(e.description)) }
  end
end
