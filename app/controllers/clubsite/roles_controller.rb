module Clubsite
  # Organizer roles, shared between all clubs. Any signed-in user may view the
  # list (the .json variant feeds the event organizer editor); editing is
  # restricted to administrators. There is intentionally no delete action:
  # deleting a role would leave dangling references from organizers.
  class RolesController < BaseController
    def index
      authorize current_club, :index?, policy_class: RolePolicy
      @roles = Role.all

      respond_to do |format|
        format.html
        format.json do
          render json: @roles.map { |role| { id: role.id, name: role.name } }
        end
      end
    end

    def edit
      authorize current_club, :edit?, policy_class: RolePolicy
      @role = find_or_build_role
    end

    def update
      authorize current_club, :update?, policy_class: RolePolicy
      @role = find_or_build_role
      if @role.update(role_params)
        flash[:success] = 'The role has been updated.'
        redirect_to '/roles/'
      else
        render :edit
      end
    end

    private

    def find_or_build_role
      params[:id].present? ? Role.find(params[:id]) : Role.new
    end

    def role_params
      params.require(:role).permit(:name, :description)
    end
  end
end
