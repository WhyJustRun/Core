module Admin
  class UsersController < BaseController
    before_action :set_user

    def show
      @counts = {
        'Results' => Result.where(user_id: @user.id).count,
        'Memberships' => Membership.where(user_id: @user.id).count,
        'Organizer roles' => Organizer.where(user_id: @user.id).count,
        'Official roles' => Official.where(user_id: @user.id).count,
        'Privileges' => Privilege.where(user_id: @user.id).count
      }
      @blocker = deletion_blocker
    end

    def destroy
      if (blocker = deletion_blocker)
        redirect_to admin_user_path(@user), alert: blocker
      elsif params[:confirm].to_s.strip != @user.id.to_s
        redirect_to admin_user_path(@user), alert: "Type the user's ID (#{@user.id}) to confirm the deletion."
      else
        summary = Tools::UserDeletion.delete(@user)
        Rails.logger.warn("[admin] user #{current_user.id} deleted user #{@user.id}: #{summary.to_json}")
        redirect_to admin_root_path,
                    notice: "Deleted user ##{@user.id}. #{summary[:results]} result(s) were kept under \"#{User::DELETED_USER_NAME}\"."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
      raise ActiveRecord::RecordNotFound if @user.deleted_placeholder?
    end

    # Why this account must not be deleted from here, if anything.
    def deletion_blocker
      if @user == current_user
        'You cannot delete your own account from the admin dashboard.'
      elsif @user.global_admin?
        'This user is a global administrator. Revoke their global privileges before deleting the account.'
      end
    end
  end
end
