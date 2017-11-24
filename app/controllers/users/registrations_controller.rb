class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create]

  def destroy
    # Don't do anything, we don't want users to have the ability to
    # automatically delete their accounts because it will impact results
    # correctness, etc. In the future, we could have a way to deactivate an
    # account if desired, but I can't really see anyone wanting that.
  end

  def build_resource(hash=nil)
    super
    user = self.resource
    if data = session['devise.linked_data'] then
      column = session['devise.linked_id_column']
      user[column] = data['uid'] if user[column].blank?
    end
  end

  private
    def check_captcha
      unless verify_recaptcha
        self.resource = resource_class.new sign_up_params
        resource.validate # Look for any other validation errors
        respond_with_navigational(resource) { render :new }
      end
    end
end
