class EventPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def update?
    unless @user
      return false
    end
    @user.has_privilege?(Settings.privileges.event.edit, @event.club) or @event.has_organizer? @user
  end

  def create?
    @user.present? && @user.has_privilege?(Settings.privileges.event.edit, @event.club)
  end

  def destroy?
    @user.present? && @user.has_privilege?(Settings.privileges.event.delete, @event.club)
  end

  # Access to the event planner page. The legacy app served the page publicly
  # and only gated the menu link; access now requires the planning privilege.
  def plan?
    @user.present? && @user.has_privilege?(Settings.privileges.event.planning, @event.club)
  end
end
