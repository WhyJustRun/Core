class MoveNonCompetitiveStatus < ActiveRecord::Migration
  def change
	  Result.all.each { |r| 
		 	if r.non_competitive == 1 then 
		  	r.update_attributes!(:status => :not_competing) 
			else
				r.update_attributes!(:status => :ok) 
			end
		}
	end
end
