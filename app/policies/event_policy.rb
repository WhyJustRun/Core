class EventPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def update?
    @user.has_privilege?(Settings.privileges.event.edit, @event.club) or event.has_organizer? @user
  end
end
