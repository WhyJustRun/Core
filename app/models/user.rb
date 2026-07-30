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
  has_many :memberships
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

  # Substring name search for the person-picker autocomplete
  def self.search_by_name(term)
    where('users.name LIKE ?', "%#{sanitize_sql_like(term.to_s)}%")
  end

  # Creates a name-only account with no email or password (a "fake" user),
  # used when registering people who don't have their own account. Saved
  # without validations, matching the legacy CakePHP action.
  def self.create_fake(name)
    user = new(name: name)
    user.save!(validate: false)
    user
  end

  # Potential duplicate account pairs (same name, case-insensitively), each
  # classified into a primary account and a duplicate account. Returns an
  # array of { primary: entry, duplicate: entry } hashes where an entry is
  # { user:, most_recent_event:, has_password: }.
  def self.duplicate_sets
    pairs = joins('INNER JOIN users AS duplicate_users ' \
                  'ON users.name LIKE duplicate_users.name AND users.id < duplicate_users.id')
            .order('users.name')
            .pluck('users.id', 'duplicate_users.id')
    pairs.map do |first_id, second_id|
      duplicate_set(includes(:club).find(first_id), includes(:club).find(second_id))
    end
  end

  # Classifies a pair of same-named users into primary and duplicate using
  # the legacy heuristics: a password beats no password, then the most
  # recent sign-in, then the most recent event attended.
  def self.duplicate_set(first, second)
    events = { first.id => first.most_recent_event, second.id => second.most_recent_event }
    first_date = events[first.id]&.fetch(:date)
    second_date = events[second.id]&.fetch(:date)

    primary, duplicate =
      if first.has_password? && !second.has_password?
        [first, second]
      elsif !first.has_password? && second.has_password?
        [second, first]
      elsif first.last_sign_in_at.present? && second.last_sign_in_at.present?
        first.last_sign_in_at > second.last_sign_in_at ? [first, second] : [second, first]
      elsif first.last_sign_in_at.present?
        [first, second]
      elsif second.last_sign_in_at.present?
        [second, first]
      elsif first_date.present? && second_date.present?
        first_date > second_date ? [first, second] : [second, first]
      elsif first_date.present?
        [first, second]
      elsif second_date.present?
        [second, first]
      else
        # Out of heuristics; matches the legacy fallback
        [second, first]
      end

    entry = lambda do |user|
      { user: user, most_recent_event: events[user.id], has_password: user.has_password? }
    end
    { primary: entry.call(primary), duplicate: entry.call(duplicate) }
  end
  private_class_method :duplicate_set

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

  # Whether this is a real account (in either password scheme) rather than a
  # name-only fake user
  def has_password?
    old_password.present? || encrypted_password.present?
  end

  # The most recent event the user has a result in, as a hash with :date,
  # :club_id and :club_acronym, or nil if they have no results
  def most_recent_event
    event = Event.includes(:club)
                 .joins(courses: :results)
                 .where(results: { user_id: id })
                 .order('events.date DESC')
                 .first
    return nil if event.nil?

    { date: event.date, club_id: event.club_id, club_acronym: event.club&.acronym }
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
                         .where(user_id: self.id)
                         .order('access_level DESC')
                         .limit(1).take
    if privilege.nil?
      0
    else
      privilege.user_group.access_level
    end
  end

  # True when the user holds a membership with the club for the given year
  def member_of?(club, year)
    Membership.exists?(user_id: id, club_id: club.id, year: year)
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
