module Clubsite
  # Grants and revokes club privileges (group memberships). Every action
  # requires the privilege edit level, and users can only see and manage
  # groups at or below their own privilege level for the club -- nobody can
  # grant (or revoke) a level above their own. Only groups belonging to the
  # current club are managed here; global groups are never offered.
  class PrivilegesController < BaseController
    def index
      authorize current_club, policy_class: PrivilegePolicy
      @groups = manageable_groups
      @privileges = Privilege.joins(:user_group, :user)
                             .where(groups: { id: @groups.select(:id) })
                             .includes(:user, :user_group)
                             .order('groups.access_level DESC, users.name')
    end

    def create
      authorize current_club, policy_class: PrivilegePolicy

      # Scoping to the current club 404s cross-club and global group ids
      group = Group.where(club_id: current_club.id).find(privilege_params[:group_id])
      raise Pundit::NotAuthorizedError if group.access_level > acting_level

      user = User.find(privilege_params[:user_id])
      if Privilege.exists?(user: user, user_group: group)
        flash[:notice] = "#{user.name} already has the #{group.name} privilege."
      elsif Privilege.create(user: user, user_group: group).persisted?
        flash[:success] = 'The privilege has been added.'
      else
        flash[:danger] = 'The privilege could not be added.'
      end
      redirect_to '/privileges/'
    end

    def update
      authorize current_club, policy_class: PrivilegePolicy

      privilege = scoped_privileges.find(params[:id])
      raise Pundit::NotAuthorizedError if privilege.user_group.access_level > acting_level

      group = Group.where(club_id: current_club.id).find(privilege_params[:group_id])
      raise Pundit::NotAuthorizedError if group.access_level > acting_level

      if Privilege.where(user_id: privilege.user_id, group_id: group.id)
                  .where.not(id: privilege.id)
                  .exists?
        flash[:notice] = "#{privilege.user.name} already has the #{group.name} privilege."
      elsif privilege.update(user_group: group)
        flash[:success] = 'The privilege has been updated.'
      else
        flash[:danger] = 'The privilege could not be updated.'
      end
      redirect_to '/privileges/'
    end

    def destroy
      authorize current_club, policy_class: PrivilegePolicy

      privilege = scoped_privileges.find(params[:id])
      raise Pundit::NotAuthorizedError if privilege.user_group.access_level > acting_level

      privilege.destroy
      flash[:success] = 'The privilege has been deleted.'
      redirect_to '/privileges/'
    end

    private

    def privilege_params
      params.require(:privilege).permit(:user_id, :group_id)
    end

    def acting_level
      @acting_level ||= current_user.privilege_level(current_club)
    end

    def manageable_groups
      Group.where(club_id: current_club.id)
           .up_to_level(acting_level)
           .order(access_level: :desc)
    end

    def scoped_privileges
      Privilege.joins(:user_group).where(groups: { club_id: current_club.id })
    end
  end
end
