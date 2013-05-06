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

  def children
    Club.where(:parent_id => id)
  end

  def self.all_ordered
    self.order(:name)
  end

  # Returns any organizations with no parent id
  def self.all_top_level
    self.where(:parent_id => nil)
  end

  # only the clubs with no child clubs.. Ideal for a map that allows people to find nearby clubs since a few organizations (Yukon) may not have any clubs beneath them, but we don't want to show COF, IOF, etc
  def self.all_leaves
    self.joins("LEFT JOIN clubs AS child_clubs ON clubs.id = child_clubs.parent_id").where("child_clubs.id IS NULL")
  end

  def all_ancestors
    ancestors = [self.id]
    self.children.each { |child|
      ancestors += child.all_ancestors
    }
    return ancestors
  end

  # finds the parent organization of the club, or returns nil
  def parent
    parent_id = self.parent_id
    if (parent_id.nil?) then
      return nil
    else
      return Club.find(parent_id)
    end
  end

  def national_clubs
    federation = self.national_federation
    if (federation.nil?) then
      return []
    else
      return federation.all_ancestors
    end
  end

  # finds the national federation associated with a club, or returns nil if there is none.
  def national_federation
    if (self.club_category.name == 'NationalFederation') then
      return self
    else
      parent = self.parent
      if (parent.nil?) then
        return nil
      else
        return parent.national_federation
      end
    end
  end
end
