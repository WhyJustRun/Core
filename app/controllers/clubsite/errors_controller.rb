module Clubsite
  # Catch-all for club domains so requests never fall through to apex routes.
  class ErrorsController < BaseController
    def not_found
      render plain: 'Not Found', status: :not_found
    end
  end
end
