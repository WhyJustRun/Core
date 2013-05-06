class HomeController < ApplicationController
  def index
    @top_level_clubs = Club.all_top_level
  end
end
