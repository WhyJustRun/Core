module Clubsite
  # Officials certification tracking (user + classification + date). Officials
  # are shared between all clubs; access is gated by the club privilege only.
  # All forms live on the index page, so edit just returns there.
  class OfficialsController < BaseController
    def index
      authorize current_club, :index?, policy_class: OfficialPolicy
      @officials = Official.includes(:user, :official_classification)
                           .order(:official_classification_id)
      @official_classifications = OfficialClassification.all
    end

    def create
      authorize current_club, :create?, policy_class: OfficialPolicy
      official = Official.new(official_params)
      if official.save
        flash[:success] = 'The official has been added.'
      else
        flash[:danger] = 'The official could not be added.'
      end
      redirect_to '/officials/'
    end

    # The legacy edit page rendered nothing; editing happens inline on index.
    def edit
      authorize current_club, :edit?, policy_class: OfficialPolicy
      redirect_to '/officials/'
    end

    def update
      authorize current_club, :update?, policy_class: OfficialPolicy
      official = Official.find(params[:id])
      if official.update(official_params)
        flash[:success] = 'The official has been updated.'
      else
        flash[:danger] = 'The official could not be updated.'
      end
      redirect_to '/officials/'
    end

    def destroy
      authorize current_club, :destroy?, policy_class: OfficialPolicy
      official = Official.find(params[:id])
      if official.destroy
        flash[:success] = 'The official was deleted.'
      else
        flash[:danger] = 'The official could not be deleted.'
      end
      redirect_to '/officials/'
    end

    private

    def official_params
      params.require(:official).permit(:user_id, :official_classification_id, :date)
    end
  end
end
