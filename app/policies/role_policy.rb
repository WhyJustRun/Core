# Roles are shared across every club (they populate every club's event
# organizer editor), so editing them is a cross-club operation and requires a
# global (club-independent) privilege. Listing stays open.
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
    user.present? && user.has_global_privilege?(Settings.privileges.role.edit)
  end

  def update?
    edit?
  end
end
