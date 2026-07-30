class MembershipPolicy
  attr_reader :user, :record

  # record is a Membership, or a Club for collection-level checks like index.
  def initialize(user, record)
    @user = user
    @record = record
  end

  # The legacy app let any signed-in user view the members list.
  def index?
    user.present?
  end

  def edit?
    user.present? && user.has_privilege?(Settings.privileges.membership.edit, club)
  end

  def update?
    edit?
  end

  def destroy?
    user.present? && user.has_privilege?(Settings.privileges.membership.delete, club)
  end

  private

  def club
    record.is_a?(Club) ? record : record.club
  end
end
