module Clubsite
  # The public club list and the club settings form for webmasters.
  class ClubsController < BaseController
    def index
      @clubs = Club.visible.order(:name)
    end

    def edit
      authorize current_club, :edit?
      @club = current_club
      set_form_collections
    end

    def update
      authorize current_club, :update?
      @club = current_club
      if @club.update(club_params)
        flash[:success] = 'Updated club'
        redirect_to '/pages/admin'
      else
        set_form_collections
        render :edit
      end
    end

    private

    def set_form_collections
      @clubs = Club.order(:name)
      @club_categories = ClubCategory.all
      # tz database identifiers, matching what the legacy PHP form offered and
      # what the timezone column stores (e.g. America/Vancouver).
      @timezones = TZInfo::Timezone.all_identifiers.sort
    end

    def club_params
      params.require(:club).permit(:name, :acronym, :location, :description, :url,
                                   :facebook_page_url, :juicer_feed_url, :layout,
                                   :timezone, :parent_id, :club_category_id,
                                   :visible, :lat, :lng)
    end
  end
end
