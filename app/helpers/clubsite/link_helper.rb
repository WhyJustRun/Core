module Clubsite
  module LinkHelper
    # URL to an event's page: relative when the event belongs to the current
    # club, absolute on the owning club's domain otherwise.
    def event_link_url(event)
      path = "/events/view/#{event.id}"
      return path if event.club_id == current_club.id

      event.club.clubsite_url(path)
    end

    # URL to pin some content to Pinterest
    def pinterest_pin_url(content_url, media_url, description)
      '//www.pinterest.com/pin/create/button/' \
        "?url=#{ERB::Util.url_encode(content_url)}" \
        "&media=#{ERB::Util.url_encode(media_url)}" \
        "&description=#{ERB::Util.url_encode(description)}"
    end
  end
end
