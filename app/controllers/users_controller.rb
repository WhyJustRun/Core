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
    @user = User.includes(includes).find_by_id(params[:user_id])
    # The placeholder owns every deleted person's results, so it has no profile
    return not_found("Couldn't find that user") if @user.nil? || @user.deleted_placeholder?
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
end
