class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :provider, :uid, :name, :club_id, :si_number, :referred_from
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

  # Facebook
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user.nil? and not auth.info.email.nil?
      user = User.where(:email => auth.info.email).first
    end

    unless user
      user = User.new
    end
    user
  end

  # Google
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    email = data["email"]
    user = User.where(:email => email).first unless email.nil?

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
end
