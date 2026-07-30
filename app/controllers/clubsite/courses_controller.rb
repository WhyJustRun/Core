module Clubsite
  # Read-only course pages: detail with results, plus serving uploaded course
  # maps. Courses are reached through their event's club.
  class CoursesController < BaseController
    include MapsController::MediaServing

    def show
      @course = Course.for_club(current_club)
                      .includes(:event, results: :user)
                      .find(params[:id])
    end

    # Displays the uploaded course map
    def map
      serve_media('Course', params[:id], params[:thumbnail])
    end
  end
end
