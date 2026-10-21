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

  test "marker changes persist only when the form is saved" do
    map = maps(:cluba_forest)
    sign_in_to_club users(:executive)
    visit_club "/maps/edit/#{map.id}"

    # Simulate the marker's hidden-field updates. Google Maps does not load in
    # tests, but the form submission path is the behavior under test.
    page.execute_script("jQuery('#MapLat').val('49.5'); jQuery('#MapLng').val('-123.45')")
    assert_in_delta 49.31, map.reload.lat.to_f

    click_button 'Save'
    assert_text 'The map has been updated.'
    assert_in_delta 49.5, map.reload.lat.to_f
    assert_in_delta(-123.45, map.lng.to_f)
  end
end
