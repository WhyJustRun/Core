class MapPolicy
  attr_reader :user, :map

  def initialize(user, map)
    @user = user
    @map = map
  end

  def edit?
    unless @user
      return false
    end
    @user.has_privilege?(Settings.privileges.maps.edit, @map.club)
  end
end
