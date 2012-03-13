class Course < ActiveRecord::Base
	has_many :results
	belongs_to :event
	
	def sorted_results
		results.sort! { |a,b|
      if a.status == :ok and b.status == :ok then
  			if a.time == b.time then
  				0
  			elsif a.time.nil? then
  				1
  			elsif b.time.nil? then
  				-1
  			else
  				a.time <=> b.time
  			end
      elsif a.status == :ok
        -1
      elsif b.status == :ok
        1
      else
        0  
      end
		}
	end
end
