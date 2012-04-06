class User < ActiveRecord::Base
  has_many :results
  has_many :organizers
  has_many :privileges
  belongs_to :club
	
  def first_name
    names = name.split
    if(names.length == 1) then
      name
    else
      names.pop
      names.join(' ')
    end
  end
	
  def last_name
    names = name.split
    if(names.length == 1) then
      nil
    else
      names.pop
    end
  end
	
  def self.check(username, password)
    require 'digest/sha2'
		
    password = Digest::SHA512.hexdigest(Settings.salt + password)
    return User.where(["username = ? AND password = ?", username, password]).first
  end
  
  def profile_url(default_club = nil)
    if(default_club.nil?) then
      domain = "http://" + club.domain
    else
      domain = "http://" + default_club.domain
    end
    
    domain + "/users/view/" + id.to_s
  end
end
