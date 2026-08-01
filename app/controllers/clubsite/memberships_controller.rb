module Clubsite
  # Club membership tracking. The index doubles as the add form; edit doubles
  # as add when no id is given (legacy URL shape).
  class MembershipsController < BaseController
    def index
      authorize current_club, :index?, policy_class: MembershipPolicy
      @memberships = current_club.memberships.includes(:user).order(year: :desc)
      @membership = current_club.memberships.new(year: Time.zone.today.year, created: Time.zone.now)
      @users = user_options
    end

    def edit
      @membership = find_or_build_membership
      authorize @membership
      @users = user_options
    end

    def update
      @membership = find_or_build_membership
      authorize @membership
      if @membership.update(membership_params)
        flash[:success] = 'The membership has been updated.'
      else
        flash[:danger] = 'The membership could not be updated.'
      end
      redirect_to '/memberships/'
    end

    def destroy
      membership = current_club.memberships.find(params[:id])
      authorize membership
      if membership.destroy
        flash[:success] = 'The membership has been deleted.'
      else
        flash[:danger] = 'The membership could not be deleted.'
      end
      redirect_to '/memberships/'
    end

    private

    # Scoping the find through current_club 404s ids belonging to other clubs.
    def find_or_build_membership
      if params[:id].present?
        current_club.memberships.find(params[:id])
      else
        current_club.memberships.new
      end
    end

    # The legacy app offered all users in the dropdown, not just club members.
    def user_options
      User.order(:name)
    end

    def membership_params
      params.require(:membership).permit(:user_id, :year, :created)
    end
  end
end
