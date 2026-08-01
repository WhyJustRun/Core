# Apex endpoints for signing in and out of club websites. Sign-in happens only
# on the apex domain; club domains receive the session via a short-lived
# signed token (see SsoToken and Clubsite::SessionsController).
class SsoController < ApplicationController
  # Sends the visitor back to the club domain with a sign-in token, going
  # through the apex sign-in form first when needed.
  def authorize
    return_host = params[:return_host].to_s
    club = find_club(return_host)
    if club.nil?
      redirect_to root_path, alert: 'Unknown club website.'
      return
    end

    unless user_signed_in?
      session[:sso_return_host] = return_host
      session[:sso_return_path] = safe_return_path
      redirect_to new_user_session_path
      return
    end

    token = SsoToken.generate(current_user, return_host)
    query = { token: token, path: safe_return_path }.compact.to_query
    redirect_to "#{club.domain_protocol}://#{return_host}/sso/consume?#{query}",
                allow_other_host: true
  end

  # Ends the apex session as part of signing out of a club website
  def logout
    return_host = params[:return_host].to_s
    club = find_club(return_host)
    sign_out(current_user) if user_signed_in?

    if club
      redirect_to "#{club.domain_protocol}://#{return_host}/users/logoutComplete",
                  allow_other_host: true
    else
      redirect_to root_path
    end
  end

  private

  # Clubs are looked up by domain, tolerating a port in the return host: the
  # club domains carry no port in production, but the visitor's Host header
  # does whenever the server runs on a non-standard port (as the system-test
  # server does). The strict format check keeps anything but a plain
  # host[:port] out of the redirect target.
  def find_club(return_host)
    return nil unless return_host.match?(/\A[a-z0-9.-]+(:\d+)?\z/i)

    Club.find_by(domain: return_host) || Club.find_by(domain: return_host.sub(/:\d+\z/, ''))
  end

  # Only relative paths may be forwarded to the club domain
  def safe_return_path
    path = params[:return_path].to_s
    path if path.start_with?('/') && !path.start_with?('//')
  end
end
