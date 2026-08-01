class Club < ApplicationRecord
  has_many :users
  has_many :events
  has_many :maps
  has_many :content_blocks
  has_many :memberships
  has_many :pages
  has_many :roles
  has_many :series
  has_many :user_groups, class_name: 'Group', foreign_key: 'group_id'
  belongs_to :club_category

  reverse_geocoded_by :lat, :lng

  scope :visible, -> { where(visible: 1) }

  validates :acronym, format: { with: /\A[a-zA-Z0-9]+\z/, message: 'may only contain letters and numbers' },
                      allow_blank: true
  validates :lat, :lng, numericality: true, allow_nil: true

  FACEBOOK_PAGE_URL_PREFIX = 'https://www.facebook.com/'.freeze
  JUICER_FEED_URL_PREFIX = 'https://www.juicer.io/feeds/'.freeze

  def children
    Club.where(:parent_id => id)
  end

  def self.all_ordered
    self.visible.order(:name)
  end

  # Returns any organizations with no parent id
  def self.all_top_level
    self.where(:parent_id => nil)
  end

  # Returns all clubs that are using WhyJustRun as their primary site
  def self.primary_whyjustrun_clubs
    self.visible.where("url LIKE CONCAT('%', domain, '%')")
  end

  # only the clubs with no child clubs.. Ideal for a map that allows people to find nearby clubs since a few organizations (Yukon) may not have any clubs beneath them, but we don't want to show COF, IOF, etc
  def self.all_leaves
    self.visible.joins("LEFT JOIN clubs AS child_clubs ON clubs.id = child_clubs.parent_id").where("child_clubs.id IS NULL")
  end

  def all_siblings
    siblings = [self.id]
    self.children.each { |child|
      siblings += child.all_siblings
    }
    return siblings
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
      return federation.all_siblings
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

  def clubsite_url(path)
    domain_protocol + "://" + domain + path
  end

  # Virtual attributes for the club settings form: the admin pastes a page/feed
  # URL (or a raw id) and only the id is stored.

  def facebook_page_url
    facebook_page_id.present? ? FACEBOOK_PAGE_URL_PREFIX + facebook_page_id : nil
  end

  def facebook_page_url=(url)
    self.facebook_page_id = self.class.trailing_url_segment(url)
  end

  def juicer_feed_url
    juicer_feed_id.present? ? JUICER_FEED_URL_PREFIX + juicer_feed_id : nil
  end

  def juicer_feed_url=(url)
    self.juicer_feed_id = self.class.trailing_url_segment(url)
  end

  # Extracts the last path segment of a URL ("https://www.facebook.com/foo/"
  # becomes "foo"). Raw ids without slashes pass through unchanged.
  def self.trailing_url_segment(value)
    value = value.to_s.strip
    return nil if value.blank?

    path = begin
      URI.parse(value).path.to_s
    rescue URI::InvalidURIError
      value
    end
    path.delete_suffix('/').split('/').last.presence
  end
end
