class Users::RegistrationsController < Devise::RegistrationsController
  include UsersHelper

  def create
    if verify_recaptcha or not show_registration_recaptcha
      super
    else
      build_resource
      clean_up_passwords(resource)
      flash.now[:alert] = 'The captcha entered was incorrect. Please re-enter the code.'
      flash.delete :recaptcha_error
      render :new
    end
  end

  def destroy
    # Don't do anything, we don't want users to have the ability to automatically delete their accounts because it will impact results correctness, etc. In the future, we could have a way to deactivate an account if desired, but I can't really see anyone wanting that.
  end

  def build_resource(hash=nil)
    super
    user = self.resource
    if data = session['devise.linked_data'] then
      column = session['devise.linked_id_column']
      user[column] = data['uid'] if user[column].blank?
    end
  end
end
