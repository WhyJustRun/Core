class PrivilegePolicy
  attr_reader :user, :record

  # record is a Privilege, or a Club for club-level checks like index
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    edit_privileges?
  end

  def create?
    edit_privileges?
  end

  def destroy?
    edit_privileges?
  end

  private

  def club
    record.is_a?(Privilege) ? record.user_group.club : record
  end

  def edit_privileges?
    user.present? && user.has_privilege?(Settings.privileges.privilege.edit, club)
  end
end
