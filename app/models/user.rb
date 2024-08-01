class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :results
  has_many :organizers
  has_many :officials
  has_many :privileges
  has_many :resources
  has_many :cross_app_sessions
  belongs_to :club

  validates :name, presence: true

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
    ::Digest::SHA512.hexdigest(Settings.passwordSalt + password)
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if club_id = session[:redirect_club_id]
        user.club_id = club_id if user.club_id.blank?
      end
    end
  end

  # Users that actually have a WJR account (aren't fake)
  def self.find_all_real
    User.where('users.email IS NOT NULL')
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
end
