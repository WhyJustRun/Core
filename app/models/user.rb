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
  has_many :resources
  has_many :cross_app_sessions
  belongs_to :club

  validates :gender, inclusion: {
    in: %w(M F),
    message: "Gender must be male, female, or unspecified",
    allow_nil: true
  }

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
      if data = session["devise.linked_data"] && session["devise.linked_data"]["extra"]["raw_info"]
        user.name = data["name"] if user.name.blank?
        user.email = data["email"] if user.email.blank?
      end

      if club_id = session[:redirect_club_id]
        user.club_id = club_id if user.club_id.blank?
      end
    end
  end

  def self.find_for_provider_and_uid(provider, uid)
    user = nil
    unless uid.nil?
      Settings.linkableAccounts.each { |column, data|
        if provider == data[:provider]
          user = User.find_by column => uid
          break
        end
      }
    end
    user
  end

  def self.find_for_omniauth(auth)
    data = auth.info
    email = data['email']
    provider = auth.provider
    uid = auth.uid
    user = User.find_for_provider_and_uid(provider, uid)
    if user.nil? and not email.nil?
      user = User.find_by email: email
      unless user.nil? or uid.nil? or provider.nil?
        Settings.linkableAccounts.each { |column, data|
          if provider == data[:provider]
            user[column] = uid
            break
          end
        }
        user.save
      end
    end

    unless user
      user = User.new
    end
    user
  end

  # Users that actually have a WJR account (aren't fake)
  def self.find_all_real
    User.where('users.email IS NOT NULL')
  end

  # Helpers
  def post_sign_in_clubsite_redirect_for_club(club, session)
    cross_session = CrossAppSession.find_by cross_app_session_id: session[:cross_app_session_id]
    # If we don't have a cross app session yet, create it.
    if cross_session.nil?
      cross_session = CrossAppSession.new_for_user(self)
      session[:cross_app_session_id] = cross_session.cross_app_session_id
      cross_session.save
    end
    "http://" + club.domain + "/users/localLogin?cross_app_session_id=" + cross_session.cross_app_session_id
  end

  def first_name
    names = name.split
    if names.length == 1
      name
    else
      names.pop
      names.join(' ')
    end
  end

  def last_name
    names = name.split
    if names.length == 1
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

  # If club is nil, will see if the user has the privilege for any club
  def has_privilege?(desired_privilege, club)
    raise ArgumentError, "desired_privilege must not be nil" if desired_privilege.nil?

    privilege_level = 0
    if club.nil?
      privilege_level = max_privilege_level
    else
      privilege_level = privilege_level(club)
    end

    (privilege_level >= desired_privilege)
  end

  # the max privilege level the user has for any club
  def max_privilege_level
    privilege = Privilege.includes(:user_group)
                         .joins('LEFT JOIN groups ON groups.id = group_id')
                         .order('access_level DESC')
                         .limit(1).take
    if privilege.nil?
      0
    else
      privilege.user_group.access_level
    end
  end

  # Find the maximum privilege level the user has for a given club
  def privilege_level(club)
    privilege = Privilege.includes(:user_group)
                         .joins('LEFT JOIN groups ON groups.id = group_id')
                         .where(user_id: self.id)
                         .where('groups.club_id = ? OR groups.club_id IS NULL', club.id)
                         .order('access_level DESC')
                         .limit(1).take
    if privilege.nil?
      0
    else
      privilege.user_group.access_level
    end
  end

  # Should check that the uid is not registered to another account before linking
  def link_account(provider, uid)
    self[provider.column.to_sym] = uid
    self.save
  end

  def unlink_account(provider)
    self[provider.column.to_sym] = nil
    self.save
  end
end
