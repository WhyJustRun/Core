class ClubsController < ApplicationController
	def index
		@clubs = Club.all
		
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
end
