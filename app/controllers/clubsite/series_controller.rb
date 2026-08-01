module Clubsite
  # Admin pages for the club's event series. Edit doubles as add when no id is
  # given (legacy URL shape).
  class SeriesController < BaseController
    def index
      authorize current_club, :index?, policy_class: SeriesPolicy
      @series = current_club.series
    end

    def edit
      @series = find_or_build_series
      authorize @series
    end

    def update
      @series = find_or_build_series
      authorize @series
      if @series.update(series_params)
        flash[:success] = 'The series has been updated.'
        redirect_to '/series/index'
      else
        render :edit
      end
    end

    private

    # Scoping the find through current_club 404s ids belonging to other clubs.
    def find_or_build_series
      if params[:id].present?
        current_club.series.find(params[:id])
      else
        current_club.series.new
      end
    end

    def series_params
      params.require(:series).permit(:acronym, :name, :color, :information, :is_current)
    end
  end
end
