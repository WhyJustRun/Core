module Clubsite
  # Read-only paginated listing of results for the club's events.
  class ResultsController < BaseController
    PER_PAGE = 20

    def index
      scope = Result.joins(course: :event).where(events: { club_id: current_club.id })

      @page = [params[:page].to_i, 1].max
      @total_pages = [(scope.count / PER_PAGE.to_f).ceil, 1].max
      @results = scope.includes(:user, course: :event)
                      .order('events.date DESC, results.id ASC')
                      .limit(PER_PAGE)
                      .offset((@page - 1) * PER_PAGE)
    end
  end
end
