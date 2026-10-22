class ApplicationController < ActionController::Base
  include Pundit::Authorization
  protect_from_forgery with: :exception

  before_action :clear_sso_state_if_necessary
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :store_location
  after_action :set_access_control_headers

  # Answers CORS preflight requests. The Access-Control-* headers themselves
  # are added by set_access_control_headers.
  def cors
    head :no_content
  end

  protected

  def clear_sso_state_if_necessary
    # if the user gets distracted while logging in and does something else and then goes back later to log in, we don't want to send them back to the club site they came from
    unless request.fullpath =~ /\/users/ || request.fullpath.start_with?('/sso')
      session.delete(:sso_return_host)
      session.delete(:sso_return_path)
    end
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
    sso_return_host = session.delete(:sso_return_host)
    if sso_return_host.present?
      query = { return_host: sso_return_host, return_path: session.delete(:sso_return_path) }.compact.to_query
      return "/sso/authorize?#{query}"
    end

    session[:previous_url] || root_path
  end


  CORS_ALLOWED_HEADERS = 'x-requested-with, Content-Type, If-Modified-Since, If-None-Match, Accept'.freeze

  # Cross-origin requests are only allowed from this app's own origins: the
  # apex domain and the club domains. Anything else gets no CORS headers, so
  # browsers refuse to expose the response to other sites.
  def set_access_control_headers
    headers['Vary'] = [headers['Vary'], 'Origin'].compact_blank.join(', ')

    origin = request.headers['Origin']
    return unless origin.present? && allowed_cors_origin?(origin)

    headers['Access-Control-Allow-Origin'] = origin
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    return unless request.options?

    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = CORS_ALLOWED_HEADERS
    # Cache the preflight response for 1 day
    headers['Access-Control-Max-Age'] = '86400'
  end

  def allowed_cors_origin?(origin)
    uri = URI.parse(origin)
    host = uri.host
    return false if host.blank?

    with_port = uri.port && ![80, 443].include?(uri.port) ? "#{host}:#{uri.port}" : host
    apex = Settings.host.to_s
    return true if [host, with_port].include?(apex) || host == apex.split(':').first

    Club.where(domain: [host, with_port]).or(Club.where(redirect_domain: [host, with_port])).exists?
  rescue URI::InvalidURIError
    false
  end

  def not_found(message)
    redirect_to '/', alert: message
  end

  def not_found_404
    raise ActionController::RoutingError.new('Not Found')
  end
end
