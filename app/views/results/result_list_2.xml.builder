xml.instruct!
xml.declare! :DOCTYPE, :ResultList, :SYSTEM, "IOFdata.dtd"
xml.ResultList do
  # TODO-RWP Event classification list
  # TODO-RWP How to do Event Races?
  xml.EventId @event.id
  @event.courses.each do |course|
    xml.ClassResult do
      xml.ClassShortName course.name
      i = 1
      course.sorted_results.each do |result|
        xml.PersonResult do
          user = result.user
          render partial: 'users/person_2', locals: { builder: xml, user: user }
          render partial: 'clubs/club_2', locals: { builder: xml, club: user.club } unless user.club.nil?

          xml.Result do
            unless result.time.nil?
              xml.Time result.time.strftime('%H:%M:%S')
              # TODO-RWP Should be a boolean
              # TODO-RWP if result.status == :ok then
              xml.ResultPosition i
              #end
            end

            # TODO-RWP (need to use the IOF 2.0.3 status names) xml.CompetitorStatus(:value => result.iof_status)
            # TODO-RWP Splits
          end
        end
        i += 1
      end
    end
  end
end
