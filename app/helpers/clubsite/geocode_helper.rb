module Clubsite
  # Reverse geocodes a point to neighbourhood/city names, with caching.
  module GeocodeHelper
    def geocode_look_up(lat, lng)
      return { 'neighbourhood' => '', 'city' => '' } if lat.blank?

      Rails.cache.fetch("geocoded/#{lat} #{lng}", expires_in: 365.days) do
        result = Geocoder.search([lat, lng]).first
        address = result&.data&.fetch('address', {}) || {}
        {
          'neighbourhood' => address['suburb'].presence || '',
          'city' => address['city'].presence || ''
        }
      end
    end
  end
end
