class ContentBlockPolicy
  attr_reader :user, :content_block

  def initialize(user, content_block)
    @user = user
    @content_block = content_block
  end

  def update?
    user.present? && user.has_privilege?(Settings.privileges.contentBlock.edit, content_block.club)
  end
end
