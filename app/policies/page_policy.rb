class PagePolicy
  attr_reader :user, :record

  # record is a Page, or a Club for club-level checks like the admin hub.
  def initialize(user, record)
    @user = user
    @record = record
  end

  def create?
    has_privilege?(Settings.privileges.page.edit)
  end

  def update?
    create?
  end

  def destroy?
    has_privilege?(Settings.privileges.page.delete)
  end

  def admin?
    has_privilege?(Settings.privileges.admin.page)
  end

  private

  def club
    record.is_a?(Page) ? record.club : record
  end

  def has_privilege?(level)
    user.present? && user.has_privilege?(level, club)
  end
end
