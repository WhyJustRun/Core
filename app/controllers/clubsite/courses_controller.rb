module Clubsite
  # Course pages and course actions: the detail page with results, serving
  # uploaded course maps, registering and unregistering participants, and the
  # course admin actions used from the event editors. Courses are reached
  # through their event's club.
  class CoursesController < BaseController
    include MapsController::MediaServing

    before_action :require_sign_in, only: %i[register unregister]

    def show
      @course = Course.for_club(current_club)
                      .includes(:event, results: :user)
                      .find(params[:id])
    end

    # Displays the uploaded course map
    def map
      serve_media('Course', params[:id], params[:thumbnail])
    end

    # Registers a user on a course. A missing or zero user id registers the
    # signed-in user; any signed-in user may register someone else. An
    # already-registered user silently redirects back to the event.
    def register
      course = find_course(params[:course_id])
      user = target_user

      # NOTE: The registration deadline is deliberately not enforced here.
      # The legacy CakePHP action never rejected late registrations
      # server-side; the UI only hides the buttons once registration closes.
      unless course.results.exists?(user_id: user.id)
        Result.create!(course: course, user: user, registrant: current_user)
        flash[:success] = 'Registration successful!'
      end
      redirect_to "/events/view/#{course.event_id}"
    end

    # Removes a user's registration row for this course only. You can always
    # unregister yourself; you can unregister someone else only if any of
    # their existing registrations (on any course) was made by you.
    def unregister
      course = find_course(params[:course_id])
      user_id = target_user_id
      unless user_id == current_user.id || Result.exists?(registrant_id: current_user.id, user_id: user_id)
        raise Pundit::NotAuthorizedError
      end

      Result.where(course_id: course.id, user_id: user_id).destroy_all
      flash[:success] = 'Unregistration successful!'
      redirect_to "/events/view/#{course.event_id}"
    end

    # Deletes a course and its results, for people who may edit the event.
    # Called via AJAX from the event courses editor.
    def destroy
      course = find_course(params[:id])
      authorize course.event, :update?

      Course.transaction do
        course.results.destroy_all
        course.destroy!
      end
      head :ok
    end

    # Stores an uploaded course map, for people who may edit the event
    def upload_map
      course = find_course(params[:id])
      unless policy(course.event).update?
        flash[:alert] = "You aren't authorized to upload a map"
        return redirect_to "/events/view/#{course.event_id}"
      end

      error =
        if params[:file].blank?
          'No file selected!'
        else
          MediaStore.new(current_club.id, 'Course').store(course.id, params[:file])
        end

      if error
        flash[:alert] = error
      else
        flash[:success] = 'Course map uploaded!'
      end
      redirect_to "/events/uploadMaps/#{course.event_id}"
    end

    private

    def find_course(id)
      Course.for_club(current_club).find(id)
    end

    # A missing or zero user id in the URL means the signed-in user (legacy
    # CakePHP URL shape)
    def target_user_id
      id = params[:user_id].to_i
      id.zero? ? current_user.id : id
    end

    def target_user
      id = params[:user_id].to_i
      id.zero? ? current_user : User.find(id)
    end

    def require_sign_in
      redirect_to '/users/login' unless user_signed_in?
    end
  end
end
