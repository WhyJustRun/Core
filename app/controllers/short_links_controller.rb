class ShortLinksController < ApplicationController
   def show
      link = ShortLink.find_by!(name: params[:name])
      redirect_to link.destination, status: :moved_permanently, allow_other_host: true
   end
end
