class SeriesPolicy
  attr_reader :user, :record

  # record is a Series, or a Club for collection-level checks like index.
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    edit?
  end

  def edit?
    user.present? && user.has_privilege?(Settings.privileges.series.edit, club)
  end

  def update?
    edit?
  end

  private

  def club
    record.is_a?(Club) ? record : record.club
  end
end
