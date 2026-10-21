module Clubsite
  # Dynamic robots.txt: club sites are hidden from crawlers outside production
  # and for clubs marked not visible.
  class RobotsController < BaseController
    def show
      hidden = Rails.configuration.x.clubsite_robots_hidden || !current_club.visible
      render plain: hidden ? "User-agent: *\nDisallow: /\n" : "User-agent: *\nDisallow:\n"
    end
  end
end
