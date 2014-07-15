# TODO-RWP How to do Event Races?
builder.Event do
  builder.Id({ type: 'WhyJustRun' }, event.id)
  builder.Name event.name
  builder.StartTime do
    builder.Date event.local_date.strftime('%F')
    builder.Time event.local_date.strftime('%T') + event.local_date.formatted_offset
    builder.ISODate event.date.strftime('%FT%T.000Z')
  end

  builder.EndTime do
    builder.Date event.local_finish_date.strftime('%F')
    builder.Time event.local_finish_date.strftime('%T') + event.local_finish_date.formatted_offset
    builder.ISODate event.finish_date.strftime('%FT%T.000Z')
  end

  classification = event.event_classification
  builder.Classification classification.iof_3_0_name unless classification.nil?

  builder.Organiser do
      render partial: 'clubs/organisation_inner', locals: { builder: builder, club: event.club }
  end

  builder.URL({ type: 'Website' }, event.url) unless event.url.nil?
  series = event.series
  unless series.nil?
    builder.Extensions do
      builder.Series do
        builder.Id({ type: 'WhyJustRun' }, series.id)
        builder.Name series.name
        builder.Acronym series.acronym
        builder.Color series.color
      end
    end
  end
  event.courses.each do |course|
    builder.Class do
      builder.Id({ type: 'WhyJustRun' }, course.id)
      builder.Name course.name
    end
  end
end
