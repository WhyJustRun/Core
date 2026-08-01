module Clubsite
  # Club-domain sign-in/out. There is no sign-in form on club domains: the
  # visitor is sent to the apex site and comes back with a short-lived signed
  # token (see SsoToken and SsoController).
  class SessionsController < BaseController
    rate_limit to: 10, within: 1.minute, only: :consume

    def new
      query = { return_host: request.host_with_port, return_path: params[:return_path] }.compact.to_query
      redirect_to "#{Settings.coreURL.chomp('/')}/sso/authorize?#{query}",
                  allow_other_host: true
    end

    def consume
      payload = SsoToken.verify(params[:token].to_s)
      user = payload && payload['host'] == request.host_with_port && User.find_by(id: payload['user_id'])
      if user
        sign_in(user)
        redirect_to safe_path
      else
        redirect_to '/', alert: 'Signing in failed. Please try again.'
      end
    end

    def destroy
      sign_out(current_user) if user_signed_in?
      query = { return_host: request.host_with_port }.to_query
      redirect_to "#{Settings.coreURL.chomp('/')}/sso/logout?#{query}",
                  allow_other_host: true
    end

    def logout_complete
      flash[:notice] = 'You have been signed out.'
      redirect_to '/'
    end

    private

    def safe_path
      path = params[:path].to_s
      path.start_with?('/') && !path.start_with?('//') ? path : '/'
    end
  end
end
