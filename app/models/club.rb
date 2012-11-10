class Club < ActiveRecord::Base
	has_many :users
	has_many :events
	has_many :maps
	has_many :groups
	has_many :content_blocks
	has_many :memberships
	has_many :pages
	has_many :roles
	has_many :series
	belongs_to :club_category
	
  def domain
    if self.custom_domain != nil then
      self.custom_domain
    else
      "#{self.acronym.downcase}.whyjustrun.ca"
    end
  end
  
  def self.all_ancestors(id)
    children = self.where(:parent_id => id).select(:id)
    ancestors = [id]
    children.each { |child|
      ancestors += self.all_ancestors(child)
    }
    return ancestors
  end
end
