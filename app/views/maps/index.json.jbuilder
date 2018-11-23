json.maps @maps do |map|
  json.(map, :id, :name, :scale, :lat, :lng, :url)
  json.club do
    json.(map.club, :id, :name)
  end

  json.map_standard do
    if(map.map_standard)
      json.(map.map_standard, :name, :color)
    end
  end
end
