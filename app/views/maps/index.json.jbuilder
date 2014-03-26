json.maps @maps do |map|
  json.(map, :id, :name, :scale, :lat, :lng, :url)
  json.club do
    json.(map.club, :id, :name)
  end
end
