class HomeController < ApplicationController
  def about_whyjustrun
    @primary_whyjustrun_clubs = Club.primary_whyjustrun_clubs
    logger.error @primary_whyjustrun_clubs.length
  end

  def about_orienteering
    @top_level_clubs = Club.all_top_level.where(:visible => true)
  end

  def robots
    render plain: <<~ROBOTS
      # See http://www.robotstxt.org/wc/norobots.html for documentation on how to use the robots.txt file
      #
      # To ban all spiders from the entire site uncomment the next two lines:
      # User-Agent: *
      # Disallow: /
    ROBOTS
  end
end
