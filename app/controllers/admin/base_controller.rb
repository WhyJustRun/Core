module Admin
  # Platform administration, available on the apex domain to users holding a
  # global (club-independent) privilege. Everyone else gets a 404 so the
  # section is not discoverable.
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_global_admin
    before_action :disable_caching

    private

    def disable_caching
      response.headers['Cache-Control'] = 'no-store'
    end

    def require_global_admin
      raise ActionController::RoutingError, 'Not Found' unless current_user.has_global_privilege?(100)
    end
  end
end
