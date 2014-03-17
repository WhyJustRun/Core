class CrossAppSession < ActiveRecord::Base
  def self.new_for_user(user)
    session = self.new
    session.cross_app_session_id = Devise.friendly_token[0, 100]
    session.user_id = user.id
    session
  end

  def self.clear_sessions_for_session_id(session_id)
    self.where(:session_id => session_id).destroy_all
  end
end
