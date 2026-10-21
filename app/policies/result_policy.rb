class ResultPolicy
  attr_reader :user, :result

  def initialize(user, result)
    @user = user
    @result = result
  end

  # Only the person who made the registration or the registered user may
  # change the registrant comment
  def edit_registrant_comment?
    user.present? && [result.registrant_id, result.user_id].include?(user.id)
  end

  # Deleting a result requires being able to edit its event
  def destroy?
    EventPolicy.new(user, result.course.event).update?
  end
end
