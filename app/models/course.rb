class Course < ActiveRecord::Base
  has_many :results
  belongs_to :event
  def sorted_results
    if is_score_o then
        results.to_a.sort! { |a,b|
          if a.status == :ok and b.status == :ok then
            if a.score_points == b.score_points then
              if a.time == b.time then
                0
              elsif a.time.nil? then
                1
              elsif b.time.nil? then
                -1
              else
                a.time <=> b.time
              end
            elsif a.score_points.nil? then
              1
            elsif b.score_points.nil? then
              -1
            else
              -(a.score_points <=> b.score_points)
            end
          elsif a.status == :ok
            -1
          elsif b.status == :ok
            1
          else
            a.status <=> b.status
          end
        }
    else
        results.to_a.sort! { |a,b|
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
            a.status <=> b.status
          end
        }
    end
    
  end
end
