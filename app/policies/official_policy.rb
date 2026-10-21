# Officials are shared between clubs, so the record is always the current
# club.
class OfficialPolicy
  attr_reader :user, :club

  def initialize(user, club)
    @user = user
    @club = club
  end

  def index?
    edit?
  end

  def create?
    edit?
  end

  def edit?
    user.present? && user.has_privilege?(Settings.privileges.official.edit, club)
  end

  def update?
    edit?
  end

  def destroy?
    user.present? && user.has_privilege?(Settings.privileges.official.delete, club)
  end
end
