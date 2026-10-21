# Map standards are shared across every club (a club's maps reference them), so
# editing them is a cross-club operation and requires a global (club-independent)
# privilege -- a per-club administrator must not be able to rename or delete a
# standard that other clubs rely on.
class MapStandardPolicy
  attr_reader :user, :club

  def initialize(user, club)
    @user = user
    @club = club
  end

  def index?
    edit?
  end

  def edit?
    user.present? && user.has_global_privilege?(Settings.privileges.mapStandard.edit)
  end

  def update?
    edit?
  end

  def destroy?
    user.present? && user.has_global_privilege?(Settings.privileges.mapStandard.delete)
  end
end
