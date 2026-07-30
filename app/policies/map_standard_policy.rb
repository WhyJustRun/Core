# Map standards are shared between clubs, so the record is always the current
# club.
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
    user.present? && user.has_privilege?(Settings.privileges.mapStandard.edit, club)
  end

  def update?
    edit?
  end

  def destroy?
    user.present? && user.has_privilege?(Settings.privileges.mapStandard.delete, club)
  end
end
