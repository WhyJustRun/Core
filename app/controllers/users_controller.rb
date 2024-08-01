class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:send_message]

  def competitor_list
    @users = User.find_all_real

    respond_to do |format|
      format.xml  { render action: :competitor_list_3, layout: false }
    end
  end

  def show
    @message ||= ""
    includes = { results: { course: { event: :club } }, organizers: { event: [:club], role: nil } };
    @user = User.includes(includes).find_by_id(params[:user_id]) || not_found("Couldn't find that user");
  end

  def send_message
    message = params[:message]
    authenticate_user!
    logger.debug params
    if verify_recaptcha
      UserMailer.send_message_email(current_user, User.find_by_id(params[:user_id]), message).deliver
      flash.now[:notice] = 'Message sent!'
      message = nil
    else
      flash.now[:alert] = 'The captcha you entered was incorrect. Please try again'
    end

    self.show
    @message = message
    render :action => 'show'
  end

  def sign_in_clubsite
    if user_signed_in?
      club = Club.find_by_id(params[:redirect_club_id])
      redirect_to(clubsite_url(club))
      session[:redirect_club_id] = nil
    else
      session[:redirect_club_id] = params[:redirect_club_id]
      options = {}
      options[:notice] = params[:flash_message] unless params[:flash_message].nil?
      redirect_to(new_user_session_path, options)
    end
  end

  def sign_out_clubsite
    if user_signed_in?
      sign_out
    end

    club = Club.find_by_id(params[:redirect_club_id])
    redirect_to("//" + club.domain + "/users/logoutComplete")
  end
end
