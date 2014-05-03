module UsersHelper
  def show_registration_recaptcha
    session['devise.linked_data'].nil?
  end
end
