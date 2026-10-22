module Clubsite
  # Catch-all for club domains so requests never fall through to apex routes.
  class ErrorsController < BaseController
    # Nothing here changes state, and bots POST to unknown paths (wp-admin and
    # friends) all day. Answer those with a 404 rather than a CSRF failure.
    skip_forgery_protection

    def not_found
      render plain: 'Not Found', status: :not_found
    end
  end
end
