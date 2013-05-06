module UsersHelper
  def show_registration_recaptcha
    session['devise.facebook_data'].nil? and session['devise.google_data'].nil?
  end
end
