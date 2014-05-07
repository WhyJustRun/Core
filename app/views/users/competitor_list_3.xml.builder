xml.CompetitorList(
  :xmlns => "http://www.orienteering.org/datastandard/3.0",
  :'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
  :iofVersion => "3.0",
  :createTime => Time.zone.now.iso8601,
  :creator => "WhyJustRun"
) do

  @users.find_each { |user|
    xml.Competitor do
      render partial: 'users/person_3', locals: { builder: xml, user: user }
      club = user.club
      unless club.nil?
        xml.Organisation do
          render partial: 'clubs/organisation_inner', locals: { builder: xml, club: club }
        end
      end

      render partial: 'users/control_cards_3', locals: { builder: xml, user: user }
    end
  }
end
