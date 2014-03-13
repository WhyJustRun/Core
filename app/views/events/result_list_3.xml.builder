# TODO-RWP Indicate whether complete or not
xml.ResultList(
  :xmlns => "http://www.orienteering.org/datastandard/3.0",
  :'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
  :iofVersion => "3.0",
  :createTime => Time.zone.now.iso8601,
  :creator => "WhyJustRun"
) do

  render partial: 'events/event_3', locals: { builder: xml, event: @event }

  @event.courses.each { |course|
    xml.comment! course.name + " entries"
    xml.ClassResult do
      xml.Course do
        xml.Length course.distance unless course.distance.nil?
        xml.Climb course.climb unless course.climb.nil?
        xml.Extensions do
          xml.ScoringType course.is_score_o ? 'Points' : 'Timed'
        end
      end

      xml.Class do
        xml.Id course.id
        xml.Name course.name
      end

      i = 1
      tied_racers = 0
      last_result = nil
      course.sorted_results.each { |result|
        xml.PersonResult do
          user = result.user
          render partial: 'users/person_3', locals: { builder: xml, user: user }

          unless user.club.nil?
            xml.Organisation do
              render partial: 'clubs/organisation_inner', locals: { builder: xml, club: user.club }
            end
          end

          xml.Result do
            unless result.time_seconds.nil? then
              xml.Time result.time_seconds
            end
            if course.is_score_o then
              unless result.score_points.nil? then
                if result.status == :ok then
                  if not last_result.nil? and last_result.time == result.time and last_result.score_points == result.score_points then
                    # tie
                    tied_racers += 1
                  else
                    tied_racers = 0
                  end
                  xml.Position({ :type => "Course" }, i - tied_racers)
                end
              end
            else
              unless result.time.nil? then
                if result.status == :ok then
                  if not last_result.nil? and last_result.time == result.time then
                    # tie
                    tied_racers += 1
                  else
                    tied_racers = 0
                  end
                  xml.Position({ :type => "Course" }, i - tied_racers)
                end
              end
            end

            xml.Status result.iof_status
            unless result.points.nil? then
              xml.Score({ :type => "WhyJustRun" }, result.points)
            end
            unless result.score_points.nil? then
              xml.Score({ :type => "Points" }, result.score_points)
            end
          end
        end

        i += 1
        last_result = result
      }
    end
  }
end
