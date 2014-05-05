module Devise
  module Strategies
    class CrossAppSession < Base
      def valid?
        params[:cross_app_session_id]
      end

      def authenticate!
        session = ::CrossAppSession.find_by cross_app_session_id: params[:cross_app_session_id]
        u = session ? session.user : nil
        if u.nil?
          fail 'Could not sign in'
        else
          session[:cross_app_session_id] = session.cross_app_session_id
          success!(u)
        end
      end
    end
  end
end
