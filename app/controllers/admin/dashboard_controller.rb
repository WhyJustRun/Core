module Admin
  class DashboardController < BaseController
    MAX_RESULTS = 50

    def show
      @query = params[:q].to_s.strip
      @users = @query.present? ? search(@query) : []
      @user_count = User.find_all_real.count
    end

    private

    def search(query)
      like = "%#{User.sanitize_sql_like(query)}%"
      matches = User.where('users.name LIKE ? OR users.email LIKE ?', like, like)
      matches = matches.or(User.where(id: query.to_i)) if query.match?(/\A\d+\z/)
      matches.where.not(id: User.where(name: User::DELETED_USER_NAME, email: nil).select(:id))
             .includes(:club).order(:name).limit(MAX_RESULTS)
    end
  end
end
