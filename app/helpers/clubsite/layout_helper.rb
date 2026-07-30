module Clubsite
  module LayoutHelper
    # Absolute URL to the apex (whyjustrun.ca) site, for cross-domain links
    # from club pages.
    def core_url(path = '/')
      Settings.coreURL.chomp('/') + path
    end

    def profile_url(user = current_user)
      core_url("/users/#{user.id}")
    end

    def admin_access?
      user_signed_in? && current_user.has_privilege?(Settings.privileges.admin.page, current_club)
    end

    def officials_access?
      user_signed_in? && current_user.has_privilege?(Settings.privileges.official.edit, current_club)
    end
  end
end
