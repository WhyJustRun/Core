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

  def save?
    edit?
  end

  def update_location?
    edit?
  end

  def destroy?
    unless @user
      return false
    end
    @user.has_privilege?(Settings.privileges.maps.delete, @map.club)
  end
end
