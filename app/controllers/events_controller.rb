class EventsController < ApplicationController
	
	def index
		limit = params[:limit] || nil
		
		if params[:user_id].nil? then
			@events = Event.all.limit(limit)
		else
			@events = Event.joins(:organizers).order('date DESC').where('organizers.user_id = ?', params[:user_id]).limit(limit)
		end
		
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
	
	def show
		@event = Event.find_cascaded(params[:id])
		respond_to do |format|
			format.xml  { render :layout => false }
			format.json  { render :json => @event }
		end
	end
	
	# IOF XML 2.0 for now
	def start_list
		unless params[:version] == '2.0.3' then
			raise ActionController::RoutingError.new('Not Found')
		end
		
		@event = Event.find(params[:id])
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
	
	# IOF XML 3.0 for now
	def entry_list
		unless params[:version] == '3.0' then
			raise ActionController::RoutingError.new('Not Found')
		end
		
		@event = Event.find(params[:id])
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
	
	# IOF XML 2.0 for now
	def result_list
		supported = ['2.0.3', '3.0']
		unless supported.include? params[:version] then
			raise ActionController::RoutingError.new('Not Found')
		end
		
		@version = params[:version]
		@event = Event.find(params[:id])
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
end
