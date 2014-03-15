class LiveResultPolicy
  attr_reader :user, :live_result

  def initialize(user, live_result)
    @user = user
    @live_result = live_result
  end

  def update?
    # delegate to the event
    Pundit.policy!(user, @live_result.event).update?
  end
end
