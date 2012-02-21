class ApplicationController < ActionController::Base
  protect_from_forgery
  
  after_filter :set_access_control_headers

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end
  
  def basic_auth
    user = authenticate_with_http_basic { |u, p| User.check(u, p) }
    if user != nil
      @current_user = user
    else
      request_http_basic_authentication
    end
  end
end
