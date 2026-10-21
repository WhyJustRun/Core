require 'application_system_test_case'

class BrandingTest < ApplicationSystemTestCase
  # Branding files are addressed through Settings.dataURL, which production
  # serves from a separate static host. The browser can only reach the test
  # server, so the data folder is pointed at a public/ subdirectory that the
  # test server's static file middleware serves.
  DATA_DIR = 'system-test-data'.freeze

  setup do
    @original_data_folder = Settings.dataFolder
    @original_data_url = Settings.dataURL
    Settings.dataFolder = Rails.public_path.join(DATA_DIR).to_s
    Settings.dataURL = "/#{DATA_DIR}/"
  end

  teardown do
    FileUtils.rm_rf(Rails.public_path.join(DATA_DIR))
    Settings.dataFolder = @original_data_folder
    Settings.dataURL = @original_data_url
  end

  test "uploading and deleting the header image and custom CSS" do
    sign_in_to_club users(:webmaster)
    visit_club '/resources/index'
    assert_selector 'h1', text: 'Resources'
    assert_text 'Not uploaded'

    within find('tr', text: 'Header Image') do
      attach_file 'resource[file]', Rails.root.join('test/fixtures/files/logo.png')
      fill_in 'resource[caption]', with: 'Club banner'
      click_button 'Upload'
    end
    assert_text 'The resource has been uploaded.'
    within find('tr', text: 'Header Image') do
      assert_selector "img[src*='headerImage_100.jpg']"
      assert_text 'Club banner'
    end

    within find('tr', text: 'CSS Style') do
      attach_file 'resource[file]', Rails.root.join('test/fixtures/files/style.css')
      click_button 'Upload'
    end
    within find('tr', text: 'CSS Style') do
      assert_link 'style.css'
    end

    header = Resource.find_by(club: clubs(:cluba), key: 'headerImage')
    style = Resource.find_by(club: clubs(:cluba), key: 'style')
    assert File.exist?(header.absolute_path)
    assert File.exist?(header.absolute_path('1300'))
    assert File.exist?(header.absolute_path('2600'))
    assert File.exist?(style.absolute_path)

    # The layout swaps the club name heading for the header image with a
    # retina srcset (the tripwire would catch a broken image URL)
    visit_club '/'
    image = find('header img')
    assert_includes image[:src], 'headerImage_1300.jpg'
    assert_includes image[:srcset], 'headerImage_1300.jpg'
    assert_includes image[:srcset], 'headerImage_2600.jpg'
    assert_no_selector 'header h1', text: 'Club A Orienteering'

    # The custom CSS link loads after the clubsite bundle so it wins the cascade
    hrefs = page.evaluate_script(
      "Array.from(document.querySelectorAll('head link[rel=stylesheet]')).map(function (l) { return l.getAttribute('href'); })"
    )
    bundle_index = hrefs.index { |href| href.include?('clubsite') }
    style_index = hrefs.index { |href| href.include?('style.css') }
    assert_not_nil bundle_index
    assert_not_nil style_index
    assert_operator style_index, :>, bundle_index

    # Deleting removes the records, the files and the layout customizations
    visit_club '/resources/index'
    within(find('tr', text: 'Header Image')) { click_button 'Delete' }
    assert_text 'The resource has been deleted.'
    within find('tr', text: 'Header Image') do
      assert_text 'Not uploaded'
    end
    within(find('tr', text: 'CSS Style')) { click_button 'Delete' }
    within find('tr', text: 'CSS Style') do
      assert_text 'Not uploaded'
    end

    assert_not File.exist?(header.absolute_path)
    assert_not File.exist?(header.absolute_path('1300'))
    assert_not File.exist?(style.absolute_path)
    assert_empty Resource.where(club: clubs(:cluba))

    visit_club '/'
    assert_selector 'header h1', text: 'Club A Orienteering'
    assert_no_selector "head link[href*='style.css']", visible: :all
  end
end
