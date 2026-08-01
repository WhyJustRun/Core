class ResourcePolicy
  attr_reader :user, :record

  # record is a Resource, or a Club for club-level checks like index
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    has_privilege?(Settings.privileges.resource.index)
  end

  def create?
    has_privilege?(Settings.privileges.resource.edit)
  end

  def destroy?
    has_privilege?(Settings.privileges.resource.delete)
  end

  private

  def club
    record.is_a?(Resource) ? record.club : record
  end

  def has_privilege?(level)
    user.present? && user.has_privilege?(level, club)
  end
end
