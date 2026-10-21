module Clubsite
  # Renders images and links for uploaded media, served through the
  # controller file-serving actions. The 'Result' type is event results files
  # (stored under the Event media type), kept for parity with the old views.
  module MediaHelper
    MEDIA_ENDPOINTS = {
      'Course' => '/courses/map/',
      'Map' => '/maps/rendering/',
      'Result' => '/events/rendering/'
    }.freeze

    MEDIA_STORE_TYPES = {
      'Course' => 'Course',
      'Map' => 'Map',
      'Result' => 'Event'
    }.freeze

    def media_image(type, id, thumbnail = nil, options = {})
      options = options.merge(srcset: "#{media_url(type, id, thumbnail)} 1x, #{media_url(type, id, thumbnail, hi_dpi: true)} 2x")
      image_tag(media_url(type, id, thumbnail), options)
    end

    def media_linked_image(type, id, thumbnail = nil, options = {}, image_options = {})
      link_to(media_image(type, id, thumbnail, image_options), media_url(type, id), options)
    end

    def media_linked_file(type, id, options = {})
      link_to('Results', media_url(type, id), options)
    end

    def media_url(type, id, thumbnail = nil, hi_dpi: false)
      raise ArgumentError, 'No media resource ID provided to build URL.' if id.blank?

      endpoint = MEDIA_ENDPOINTS.fetch(type)
      thumbnail = MediaStore.double_size(thumbnail) if hi_dpi && thumbnail
      thumbnail ? "#{endpoint}#{id}/#{thumbnail}" : "#{endpoint}#{id}"
    end

    def media_exists?(type, id, thumbnail = nil)
      MediaStore.new(current_club.id, MEDIA_STORE_TYPES.fetch(type)).exists?(id, thumbnail)
    end
  end
end
