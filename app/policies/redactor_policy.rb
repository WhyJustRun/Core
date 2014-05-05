class RedactorPolicy
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def store_file?
    # There are a lot of scenarios where the user might be doing rich text editing..
    is_organizer = Organizer.where(user_id: user.id).exists?
    (is_organizer or
     @user.has_privilege?(Settings.privileges.event.edit, nil) or
     @user.has_privilege?(Settings.privileges.contentBlock.edit, nil) or
     @user.has_privilege?(Settings.privileges.page.edit, nil) or
     @user.has_privilege?(Settings.privileges.series.edit, nil) or
     @user.has_privilege?(Settings.privileges.maps.edit, nil))
  end
end
