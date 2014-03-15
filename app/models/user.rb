class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]

  has_many :results
  has_many :organizers
  has_many :privileges
  belongs_to :club

  # Migrate to the Devise password scheme
  # Inspired by https://gist.github.com/Bertg/966503
  def valid_password?(password_input)
    if using_old_validation?
      Devise.secure_compare(cakephp_password_digest(password_input), self.old_password).tap do |validated|
        if validated
          self.password = password_input
          self.old_password = nil
          self.save(:validate => false)
        end
      end
    else
      super(password_input)
    end
  end

  def using_old_validation?
    not self.old_password.nil? and encrypted_password.empty?
  end

  def cakephp_password_digest(password)
    require "digest/sha2"
    ::Digest::SHA512.hexdigest(Settings.salt + password)
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.name = data["name"] if user.name.blank?
        user.email = data["email"] if user.email.blank?
      end

      if data = session['devise.google_data'] && session['devise.google_data']['extra']['raw_info']
        user.name = data['name'] if user.name.blank?
        user.email = data['email'] if user.email.blank?
      end

      if club_id = session[:redirect_club_id]
        user.club_id = club_id if user.club_id.blank?
      end
    end
  end

  def self.find_for_provider_and_uid(provider, uid)
    user = nil
    unless provider.nil? or uid.nil?
      user = User.where(:provider => provider, :uid => uid).first
    end
    user
  end

  def self.find_for_omniauth(auth, signed_in_resource=nil)
    data = auth.info
    email = data['email']
    provider = auth.provider
    uid = auth.uid
    user = User.find_for_provider_and_uid(provider, uid)
    if user.nil? and not email.nil?
      user = User.where(:email => email).first
      unless user.nil?
        user.provider = provider
        user.uid = uid
        user.save
      end
    end

    unless user
      user = User.new
    end
    user
  end

  # Handle sign in/out by updating the cross app session for the user
  # These methods are called by warden hooks defined in config/initializers/devise.rb
  # These should be idempotent, as they are also called by app controller after_sign_in_path_for because it seems like the warden hooks don't get called in time after sign up
  def sign_in
    CrossAppSession.clear_sessions_for_user(self)
    CrossAppSession.new_for_user(self).save
  end

  def sign_out
    CrossAppSession.clear_sessions_for_user(self)
  end

  # Helpers
  def post_sign_in_clubsite_redirect_for_club(club)
    session = CrossAppSession.find_by_user_id(self.id)
    # this might be the case if the user is already signed in on this computer but signed out on another computer so the cross app session was deleted..
    if (session.nil?) then
      session = CrossAppSession.new_for_user(self)
      session.save
    end
    "http://" + club.domain + "/users/localLogin?cross_app_session_id=" + session.cross_app_session_id
  end

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

  def can_message
    not self.email.nil?
  end

  # We don't require an email for fake accounts
  def email_required?
    not password.nil?
  end

  def password_required?
    super if not email.nil?
  end

  def has_privilege?(desired_privilege, club)
    raise ArgumentError, "desired_privilege must not be nil" if desired_privilege.nil?
    (privilege_level(club) >= desired_privilege)
  end

  # Find the maximum privilege level the user has for a given club
  def privilege_level(club)
    privilege = Privilege.includes(:user_group)
                         .joins('LEFT JOIN groups ON groups.id = group_id')
                         .where(user_id: self.id)
                         .where('groups.club_id = ? OR groups.club_id IS NULL', club.id)
                         .order('access_level DESC')
                         .limit(1).take
    privilege.user_group.access_level
  end
end
