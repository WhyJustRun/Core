class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery

  before_filter :clear_redirect_club_if_necessary
  before_filter :configure_permitted_parameters, if: :devise_controller?
  after_filter :store_location
  after_filter :set_access_control_headers

  def cors
    # Cache the OPTIONS response for 1 day
    headers['Access-Control-Max-Age'] = '86400'
    render text: nil
  end

  protected

  def clear_redirect_club_if_necessary
    # if the user gets distracted while logging in and does something else and then goes back later to log in, we don't want to redirect them to the source club in that case
    session.delete(:redirect_club_id) unless request.fullpath =~ /\/users/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:club_id, :name, :si_number, :referred_from, :password, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:club_id, :name, :si_number, :email, :password, :current_password])
  end

  def store_location
    # store last url as long as it isn't a /users path, except if it is a profile page
    if not request.xhr? and (not (request.fullpath =~ /\/users/) or request.fullpath =~ /\/users\/\b\d+\b/) then
      session[:previous_url] = request.fullpath
    end

  end

  def after_sign_in_path_for(resource)
    redirect_club_id = session[:redirect_club_id]
    unless redirect_club_id.nil? then
      club = Club.find_by_id(redirect_club_id)
      session[:redirect_club_id] = nil
      current_user.post_sign_in_clubsite_redirect_for_club(club, session)
    else
      session[:previous_url] || root_path
    end
  end


  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match,Accept'
    headers['Access-Control-Request-Method'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Credentials'] = 'true'

    head(:ok) if request.request_method == "OPTIONS"
  end

  def not_found(message)
    redirect_to '/', alert: message
  end

  def not_found_404
    raise ActionController::RoutingError.new('Not Found')
  end
end
