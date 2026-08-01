module Clubsite
  # Club-scoped user endpoints: the person-picker JSON autocomplete, creating
  # name-only ("fake") users when registering others, and the duplicate
  # account merge tools.
  class UsersController < BaseController
    before_action :require_sign_in

    # JSON autocomplete for the person pickers. `term` is matched as a
    # substring; `allowFake=false` restricts the results to accounts with an
    # email address. Requiring sign-in is a deliberate hardening over the
    # legacy app, which served this anonymously.
    def index
      users = []
      if params[:term].present?
        users = User.search_by_name(params[:term]).limit(8)
        users = users.merge(User.find_all_real) if params[:allowFake] == 'false'
      end
      render json: users.map { |user| { name: user.name, identifiableName: user.name, id: user.id } }
    end

    # Creates a name-only fake user so that people without an account can be
    # registered. Responds with the new user's id as a bare JSON value, the
    # contract expected by register-others.js and result-editor.js. A name is
    # required (and length-bounded) so the endpoint can't be used to flood the
    # users table with empty/garbage rows.
    def create
      name = params[:userName].to_s.strip
      if name.blank? || name.length > 255
        return render json: { error: 'A valid name is required.' }, status: :unprocessable_entity
      end

      user = User.create_fake(name)
      render json: user.id
    end

    def merge
      authorize current_club, :merge?, policy_class: UserPolicy
      perform_merge(params[:target_id], params[:source_id])
      redirect_to '/users/showDuplicates'
    end

    # Lists detected duplicate accounts with merge buttons; POST performs a
    # manual merge of two picked accounts
    def show_duplicates
      authorize current_club, :show_duplicates?, policy_class: UserPolicy
      # Merge is a lower privilege level than edit. Merge-level users may only
      # merge people associated with their club, whereas edit-level and global
      # admins can merge anyone (see #can_merge_any_user?).
      @can_merge_any_user = can_merge_any_user?

      if request.post?
        if perform_merge(params.dig(:user, '0', :user_id), params.dig(:user, '1', :user_id))
          flash[:success] = 'Users merged'
        else
          flash[:notice] = 'Users not merged'
        end
        return redirect_to '/users/showDuplicates'
      end

      @users = User.order(:name)
      @duplicates = User.duplicate_sets
      unless @can_merge_any_user
        @duplicates = @duplicates.select do |match|
          related_to_club?(match[:primary]) || related_to_club?(match[:duplicate])
        end
      end
    end

    private

    # Merges the source account into the target account. Missing users, merging
    # an account into itself, and merges the current user isn't allowed to
    # perform are all silently ignored (matching the legacy behavior). Returns
    # whether a merge happened.
    def perform_merge(target_id, source_id)
      return false if target_id.blank? || target_id.to_s == source_id.to_s

      target = User.find_by(id: target_id)
      source = User.find_by(id: source_id)
      return false if target.nil? || source.nil?
      return false unless can_merge?(target) && can_merge?(source)

      Tools::UserMerge.merge(target, source)
      true
    end

    # Guards each account in a merge. A merge re-points the source's privileges
    # onto the target, so it is a privilege-granting operation and must not let
    # a club admin absorb rights they don't already hold:
    #   * only a global admin may merge an account that holds a global
    #     (cross-club) privilege -- this is what stops a club webmaster from
    #     merging a platform administrator into their own account;
    #   * mergers who can't merge arbitrary accounts are restricted to accounts
    #     associated with the current club.
    def can_merge?(user)
      return false if user.global_admin? && !current_user.global_admin?
      return true if can_merge_any_user?

      user_related_to_club?(user)
    end

    def can_merge_any_user?
      @can_merge_any_user ||=
        current_user.global_admin? ||
        UserPolicy.new(current_user, current_club).edit_any?
    end

    # A duplicate entry concerns the current club when the account or its
    # most recent event belongs to the club
    def related_to_club?(entry)
      entry[:user].club_id == current_club.id ||
        entry[:most_recent_event]&.dig(:club_id) == current_club.id
    end

    # Whether an account is associated with the current club: it belongs to the
    # club, holds a membership, or has competed at one of the club's events.
    def user_related_to_club?(user)
      user.club_id == current_club.id ||
        Membership.exists?(user_id: user.id, club_id: current_club.id) ||
        Result.joins(course: :event)
              .where(events: { club_id: current_club.id }, results: { user_id: user.id })
              .exists?
    end

    def require_sign_in
      return if user_signed_in?

      if request.format.json?
        head :unauthorized
      else
        redirect_to '/users/login'
      end
    end
  end
end
