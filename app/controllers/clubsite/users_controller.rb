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
    # contract expected by register-others.js and result-editor.js.
    def create
      user = User.create_fake(params[:userName])
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
      # merge people associated with their club, whereas edit-level users can
      # merge anyone.
      @can_merge_any_user = UserPolicy.new(current_user, current_club).edit_any?

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

    # Merges the source account into the target account. Missing users and
    # merging an account into itself are ignored (matching the legacy
    # behavior). Returns whether a merge happened.
    def perform_merge(target_id, source_id)
      return false if target_id.blank? || target_id.to_s == source_id.to_s

      target = User.find_by(id: target_id)
      source = User.find_by(id: source_id)
      return false if target.nil? || source.nil?

      Tools::UserMerge.merge(target, source)
      true
    end

    # A duplicate entry concerns the current club when the account or its
    # most recent event belongs to the club
    def related_to_club?(entry)
      entry[:user].club_id == current_club.id ||
        entry[:most_recent_event]&.dig(:club_id) == current_club.id
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
