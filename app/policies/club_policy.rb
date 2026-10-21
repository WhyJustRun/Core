class ClubPolicy
  attr_reader :user, :club

  def initialize(user, club)
    @user = user
    @club = club
  end

  def edit?
    user.present? && user.has_privilege?(Settings.privileges.club.edit, club)
  end

  def update?
    edit?
  end
end
