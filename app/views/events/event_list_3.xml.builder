xml.instruct!
xml.EventList(
  :xmlns       => "http://www.orienteering.org/datastandard/3.0",
  :'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
  :iofVersion  => "3.0",
  :createTime  => Time.zone.now.iso8601,
  :creator     => "WhyJustRun"
) do
  @events.each do |event|
    render partial: 'events/event_3', locals: { builder: xml, event: event }
  end
end
