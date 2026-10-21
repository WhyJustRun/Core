# Authorizes the club-site user admin tools. The record is the club the
# check is scoped to.
class UserPolicy
  attr_reader :user, :club

  def initialize(user, club)
    @user = user
    @club = club
  end

  def merge?
    user.present? && user.has_privilege?(Settings.privileges.user.merge, club)
  end

  def show_duplicates?
    merge?
  end

  # Users at the edit level may merge accounts unrelated to the club and get
  # the manual merge form
  def edit_any?
    user.present? && user.has_privilege?(Settings.privileges.user.edit, club)
  end
end
