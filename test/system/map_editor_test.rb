require 'application_system_test_case'

class MapEditorTest < ApplicationSystemTestCase
  teardown do
    # Remove any files written to the data volume during the test
    FileUtils.rm_rf(File.join(Settings.dataFolder, clubs(:cluba).id.to_s))
  end

  test "creating a map with an image upload renders the thumbnails" do
    sign_in_to_club users(:executive)
    visit_club '/maps/edit'
    assert_selector 'h1', text: 'Add Map'

    fill_in 'map[name]', with: 'Browser Test Map'
    fill_in 'map[scale]', with: '12500'
    attach_file 'map[image]', Rails.root.join('test/fixtures/files/logo.png')
    click_button 'Save'

    assert_text 'The map has been updated.'
    map = Map.find_by(name: 'Browser Test Map')
    assert_not_nil map
    assert_equal 12_500, map.scale
    assert MediaStore.new(clubs(:cluba).id, 'Map').exists?(map.id)

    # The map page shows the uploaded rendering (a 404 here would also trip
    # the console-error teardown)
    assert_selector 'h1', text: 'Browser Test Map'
    assert_selector "img[src*='/maps/rendering/#{map.id}']"
  end

  test "editing a map persists changes and shows the existing image" do
    map = maps(:cluba_forest)
    upload = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/logo.png'), 'image/png')
    MediaStore.new(clubs(:cluba).id, 'Map').store(map.id, upload)

    sign_in_to_club users(:executive)
    visit_club "/maps/edit/#{map.id}"
    assert_selector 'h1', text: 'Edit Map'
    assert_selector "img[src*='/maps/rendering/#{map.id}']"

    fill_in 'map[name]', with: 'Forest Map West'
    click_button 'Save'

    assert_text 'The map has been updated.'
    assert_selector 'h1', text: 'Forest Map West'
    assert_equal 'Forest Map West', map.reload.name
  end

  test "the draggable marker update endpoint persists the new location" do
    map = maps(:cluba_forest)
    sign_in_to_club users(:executive)
    visit_club "/maps/edit/#{map.id}"

    # Google Maps never loads in tests, so simulate the marker drop by posting
    # what map.js posts, from the page context (exercises the CSRF wiring).
    page.execute_script("jQuery.post('/maps/update/#{map.id}/49.5/-123.45')")
    wait_for_condition(message: 'map location was not updated') do
      map.reload.lat.to_f.round(2) == 49.5
    end
    assert_in_delta(-123.45, map.lng.to_f)
  end
end
