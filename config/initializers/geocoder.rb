Geocoder.configure(
  lookup: :nominatim,
  units: :km,
  timeout: 5,
  # Nominatim's usage policy requires an identifying User-Agent
  http_headers: { 'User-Agent' => 'WhyJustRun (support@whyjustrun.ca)' },
  cache: Rails.cache
)
