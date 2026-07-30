# Roles are shared between clubs, so the record is always the current club.
class RolePolicy
  attr_reader :user, :club

  def initialize(user, club)
    @user = user
    @club = club
  end

  # Any signed-in user may list roles: the list feeds the event organizer
  # editor (roles/index.json).
  def index?
    user.present?
  end

  def edit?
    user.present? && user.has_privilege?(Settings.privileges.role.edit, club)
  end

  def update?
    edit?
  end
end
