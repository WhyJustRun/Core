module Clubsite
  # Admin pages for map standards, shared between all clubs.
  class MapStandardsController < BaseController
    def index
      authorize current_club, :index?, policy_class: MapStandardPolicy
      @map_standards = MapStandard.all
    end

    def edit
      authorize current_club, :edit?, policy_class: MapStandardPolicy
      @map_standard = find_or_build_map_standard
    end

    def update
      authorize current_club, :update?, policy_class: MapStandardPolicy
      @map_standard = find_or_build_map_standard
      if @map_standard.update(map_standard_params)
        flash[:success] = 'The map standard has been updated.'
        redirect_to '/mapStandards/'
      else
        render :edit
      end
    end

    def destroy
      authorize current_club, :destroy?, policy_class: MapStandardPolicy
      map_standard = MapStandard.find(params[:id])
      if map_standard.destroy
        flash[:success] = 'The map standard has been deleted.'
      else
        flash[:danger] = 'The map standard could not be deleted.'
      end
      redirect_to '/mapStandards/'
    end

    private

    def find_or_build_map_standard
      params[:id].present? ? MapStandard.find(params[:id]) : MapStandard.new
    end

    def map_standard_params
      params.require(:map_standard).permit(:name, :color, :description)
    end
  end
end
