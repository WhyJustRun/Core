# Apex endpoints for signing in and out of club websites. Sign-in happens only
# on the apex domain; club domains receive the session via a short-lived
# signed token (see SsoToken and Clubsite::SessionsController).
class SsoController < ApplicationController
  # Sends the visitor back to the club domain with a sign-in token, going
  # through the apex sign-in form first when needed.
  def authorize
    club = Club.find_by(domain: params[:return_host].to_s)
    if club.nil?
      redirect_to root_path, alert: 'Unknown club website.'
      return
    end

    unless user_signed_in?
      session[:sso_return_host] = club.domain
      session[:sso_return_path] = safe_return_path
      redirect_to new_user_session_path
      return
    end

    token = SsoToken.generate(current_user, club.domain)
    query = { token: token, path: safe_return_path }.compact.to_query
    redirect_to "#{club.domain_protocol}://#{club.domain}/sso/consume?#{query}",
                allow_other_host: true
  end

  # Ends the apex session as part of signing out of a club website
  def logout
    club = Club.find_by(domain: params[:return_host].to_s)
    sign_out(current_user) if user_signed_in?

    if club
      redirect_to "#{club.domain_protocol}://#{club.domain}/users/logoutComplete",
                  allow_other_host: true
    else
      redirect_to root_path
    end
  end

  private

  # Only relative paths may be forwarded to the club domain
  def safe_return_path
    path = params[:return_path].to_s
    path if path.start_with?('/') && !path.start_with?('//')
  end
end
