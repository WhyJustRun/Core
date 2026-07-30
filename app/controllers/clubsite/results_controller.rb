module Clubsite
  # Paginated listing of results for the club's events, plus the registrant
  # comment editor and result deletion used by the event pages.
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

    # POST target of the comment modal on the event page. Only the person who
    # made the registration or the registered user may edit the comment.
    def edit_registrant_comment
      return redirect_to '/users/login' unless user_signed_in?

      result = find_result(params.require(:result)[:id])
      authorize result, :edit_registrant_comment?
      result.update!(registrant_comment: params[:result][:registrant_comment])
      redirect_to "/events/view/#{result.course.event_id}"
    end

    # Deletes a result row (called via AJAX from the result editor), for
    # people who may edit the event
    def destroy
      result = find_result(params[:id])
      authorize result, :destroy?
      result.destroy!
      head :ok
    end

    private

    # Results are reachable only through the current club's events
    def find_result(id)
      Result.joins(course: :event).where(events: { club_id: current_club.id }).find(id)
    end
  end
end
