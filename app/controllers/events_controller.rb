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
	
	# TODO-RWP This could use a refactor.
	# TODO-RWP Need to switch to Devise
	def process_result_list
		require 'nokogiri'
		
		user = User.where(:api_key => params[:apiKey]).all.first
		if params[:apiKey].blank? or user.blank? then
			render :status => :unauthorized
			return
		end
		
		if Organizer.where(:event_id => params[:id], :user_id => user.id).count == 0 then
			render :status => :unauthorized
			return
		end
		
		event = {}
		# Strategy:
		# 1. Extract event, and update database if necessary
		# 2. Extract courses, and update database if necessary
		# 3. Extract results, and update database if necessary
		doc = Nokogiri::XML(request.body.read)
		
		results = {}
		results.default = []
		
		if(params[:version] == '2.0.3') then
			
		elsif(params[:version] == '3.0') then
			doc.css('ClassResult').each do |course|
				course_results = []
				course_id = (course.at_css('Class'))['idref'].to_i
				course.xpath("*[name()='PersonResult']").each do |result|
					start_time = result.at_css('Result > StartTime').content
					end_time = result.at_css('Result > EndTime').content
					time_node = result.at_css('Result > Time')
					person_id_node = result.at_css('Person > Id')
					user_id = nil
					unless person_id_node.nil? then user_id = person_id_node.content.to_i end
					unless time_node.nil? then time = time_node.content end
					status_node = result.at_css('Result > Status')
					unless status_node.nil? then status = status_node.content end
					if status.blank? then
						status = "OK"
					end
					unless(time.blank?) then time = time.to_i.seconds.since(Time.utc(0)) end
					unless start_time.blank? or end_time.blank? then
						time = (Time.parse(end_time) - Time.parse(start_time)).seconds.since(Time.utc(0))
					end
					course_results << {
						:name => result.at_css('Person > Name > Given').content + " " + result.at_css('Person > Name > Family').content,
						:id => user_id,
						:time => time,
						:status => status
					}
					results[course_id] = course_results
				end
			end

		else 
			raise ActionController::RoutingError.new('Not Found')
		end
		
		logger.info results.inspect
		
		event = Event.find(params[:id])
		event.results_posted = 1
		event.save
		
		event.courses.each { |course|
			existing_results = course.results
			results[course.id].each { |result|
				matched = false
				# Try to match up results - could have a better algorithm that isn't O(n^2)
				existing_results.each { |existing_result|
					
					if(existing_result.user.id == result[:id]) then
						matched = true
					elsif(result[:id].blank? and not result[:name].blank? and existing_result.user.name == result[:name]) then
						matched = true
					end
					
					if matched then 
						existing_result.iof_status = result[:status]
						existing_result.time = result[:time]
						existing_result.save
						break
					end
				}
				
				unless matched then
					# create a new result if it isn't already in the database..
					if result[:id].blank? then
						matches = User.where(:name => result[:name]).all
						if(matches.length == 1) then
							new_result = Result.create(:user_id => matches.first.id, :time => result[:time], :course_id => course.id)
							new_result.save
						elsif(matches.length > 1)
							# don't insert if there are more than one possible people..
							render :status => :bad_request
							return
						else
							# create new user
							new_result = Result.create(:time => result[:time], :course_id => course.id)
							user = User.create(:name => result[:name])
							new_result.user_id = user.id
							new_result.save
						end
					else
						new_result = Result.create(:user_id => result[:id], :time => result[:time], :course_id => course.id)
						new_result.save
					end
				end
			}
		}
				
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
end
