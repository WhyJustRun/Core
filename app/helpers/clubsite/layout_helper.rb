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

    # Redactor is licensed software mounted into public/redactor at deploy
    # time; rich text editing degrades gracefully when it is absent.
    def redactor_available?
      File.exist?(Rails.public_path.join('redactor', 'redactor.js'))
    end

    def redactor_script_tags
      return unless redactor_available?

      javascript_include_tag('/redactor/redactor.js', skip_pipeline: true) +
        stylesheet_link_tag('/redactor/redactor.css', skip_pipeline: true)
    end
  end
end
