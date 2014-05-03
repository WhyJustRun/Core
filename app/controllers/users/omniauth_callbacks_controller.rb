class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    authenticate_user(Settings.linkableAccounts.facebook_id, request.env["omniauth.auth"])
  end

  def google_oauth2
    authenticate_user(Settings.linkableAccounts.google_id, request.env["omniauth.auth"])
  end

  def authenticate_user(provider, data)
    if current_user
      existing_user = User.find_for_provider_and_uid(provider.provider, data.uid)
      if existing_user
        flash[:alert] = 'That ' + provider.name + ' account is already linked to another WhyJustRun account (' + existing_user.name + ').'
      else
        flash[:notice] = 'Successfully linked your ' + provider.name + ' account to your WhyJustRun account.'
        current_user.link_account(provider, data.uid)
      end

      redirect_to user_path(current_user.id)
    else
      @user = User.find_for_omniauth(data)

      if @user.persisted?
        @user
        sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
        set_flash_message(:notice, :success, :kind => provider.name) if is_navigational_format?
      else
        session["devise.linked_data"] = data
        session['devise.linked_id_column'] = provider.column
        redirect_to new_user_registration_url
      end
    end
  end

  def after_omniauth_failure_path_for(scope)
    root_path
  end
end
