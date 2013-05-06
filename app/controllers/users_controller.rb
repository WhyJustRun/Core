class UsersController < ApplicationController

  def show
    @message ||= ""
    @user = User.find_by_id(params[:user_id])
  end

  def send_message
    message = params[:message]
    authenticate_user!
    logger.debug params
    if verify_recaptcha then
      UserMailer.send_message_email(current_user, User.find_by_id(params[:user_id]), message).deliver
      flash.now[:notice] = 'Message sent!'
      message = nil
    else
      flash.now[:alert] = 'The captcha you entered was incorrect. Please try again';
    end 

    self.show
    @message = message
    render :action => 'show'
  end

  def sign_in_clubsite
    if user_signed_in? then
      club = Club.find_by_id(params[:redirect_club_id])
      redirect_to(current_user.post_sign_in_clubsite_redirect_for_club(club))
      session[:redirect_club_id] = nil
    else
      session[:redirect_club_id] = params[:redirect_club_id]
      options = {}
      options[:notice] = params[:flash_message] unless params[:flash_message].nil?
      redirect_to(new_user_session_path, options)
    end
  end

  def sign_out_clubsite
    if user_signed_in? then
      sign_out
    end

    club = Club.find_by_id(params[:redirect_club_id])
    redirect_to("http://" + club.domain + "/users/logoutComplete");
  end
end

