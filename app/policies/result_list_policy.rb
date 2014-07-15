class ResultListPolicy
  attr_reader :user, :result_list

  def initialize(user, result_list)
    @user = user
    @result_list = result_list
  end

  def update_result_list?
    # delegate to the event
    Pundit.policy!(user, @result_list.event).update?
  end

  def update_live_result_list?
    update_result_list?
  end
end
