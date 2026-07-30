require 'test_helper'

class ClubsitePagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Only the tables this feature touches, so the test is independent of
  # fixtures belonging to other features.
  self.fixture_table_names = %w[club_categories clubs groups users privileges pages content_blocks]

  setup do
    host! 'cluba.test'
  end

  test "home renders the club's content blocks" do
    get '/'
    assert_response :success
    block = content_blocks(:cluba_general_information)
    assert_select "div#content-block-#{block.id}.content-block", text: 'Welcome to Club A!'
  end

  test "home content blocks are not editable for signed out visitors" do
    get '/'
    assert_response :success
    assert_select '.content-block.wjr-editable', count: 0
  end

  test "home content blocks are editable for privileged users" do
    sign_in users(:executive)
    get '/'
    assert_response :success
    block = content_blocks(:cluba_general_information)
    assert_select "div#content-block-#{block.id}.content-block.wjr-editable"
  end

  test "club with the other layout renders the other home template" do
    host! 'clubb.test'
    get '/'
    assert_response :success
    assert_select 'h1', 'Orienteering Canada Database'
  end

  test 'contact renders its content blocks' do
    get '/pages/contact'
    assert_response :success
    assert_select 'h1', 'Contact Us'
    block = content_blocks(:cluba_contact)
    assert_select "div#content-block-#{block.id}.content-block", text: 'Contact Club A at cluba@example.com.'
  end

  test 'contact auto-seeds default content blocks on first read' do
    host! 'clubb.test'
    assert_difference -> { clubs(:clubb).content_blocks.where(key: 'contact').count }, 1 do
      get '/pages/contact'
    end
    assert_response :success
    assert_select '.content-block', text: 'No contact information has been entered yet.'
  end

  test "resources lists the club's resource pages" do
    get '/pages/resources'
    assert_response :success
    page = pages(:cluba_trail_guide)
    assert_select "a[href=?]", "/pages/#{page.id}", text: 'Trail Guide'
    # Pages of other clubs are not listed
    assert_select 'a', text: 'Club B Handbook', count: 0
    # No add form for signed out visitors
    assert_select 'form[action="/pages/add"]', count: 0
  end

  test 'resources shows the add page form to editors' do
    sign_in users(:executive)
    get '/pages/resources'
    assert_response :success
    assert_select 'form[action="/pages/add"]'
  end

  test 'export renders' do
    get '/pages/export'
    assert_response :success
    assert_select 'code', text: /cluba\.whyjustrun\.ca\/events\.embed/
  end

  test 'admin redirects users without the admin privilege' do
    sign_in users(:executive)
    get '/pages/admin'
    assert_response :redirect
    assert_redirected_to '/'
  end

  test 'admin redirects signed out visitors' do
    get '/pages/admin'
    assert_response :redirect
  end

  test 'admin renders for the webmaster' do
    sign_in users(:webmaster)
    get '/pages/admin'
    assert_response :success
    assert_select 'h1', 'Admin tools'
    assert_select 'a[href=?]', Settings.coreURL.chomp('/') + "/club/#{clubs(:cluba).id}/participation_report.csv"
    # Webmaster (90) has the user merge privilege (90)
    assert_select 'a[href="/users/showDuplicates/"]'
  end

  test 'a dynamic page renders its title and content' do
    page = pages(:cluba_trail_guide)
    get "/pages/#{page.id}"
    assert_response :success
    assert_select "h1#page-resource-title-#{page.id}", text: 'Trail Guide'
    assert_select "div#page-resource-#{page.id} p", text: 'Club A trails and how to find them.'
  end

  test 'an unknown page slug 404s' do
    get '/pages/nonsense'
    assert_response :not_found
  end

  test "another club's page id 404s" do
    host! 'clubb.test'
    get "/pages/#{pages(:cluba_trail_guide).id}"
    assert_response :not_found
  end

  test 'a privileged user can edit a content block' do
    sign_in users(:executive)
    block = content_blocks(:cluba_general_information)
    post '/contentBlocks/edit', params: { id: "content-block-#{block.id}", value: '<h2>Updated welcome!</h2>' }
    assert_response :success
    assert_equal '<h2>Updated welcome!</h2>', block.reload.content
    assert_equal '<h2>Updated welcome!</h2>', response.body
  end

  test 'an unprivileged user cannot edit a content block' do
    sign_in users(:member)
    block = content_blocks(:cluba_general_information)
    original_content = block.content
    post '/contentBlocks/edit', params: { id: "content-block-#{block.id}", value: 'hacked' }
    assert_response :redirect
    assert_equal original_content, block.reload.content
  end

  test "a content block of another club cannot be edited through this club's site" do
    sign_in users(:executive)
    block = content_blocks(:clubb_general_information)
    original_content = block.content
    post '/contentBlocks/edit', params: { id: "content-block-#{block.id}", value: 'hacked' }
    assert_response :not_found
    assert_equal original_content, block.reload.content
  end

  test 'a privileged user can edit page content' do
    sign_in users(:executive)
    page = pages(:cluba_trail_guide)
    post '/pages/edit', params: { id: "page-resource-#{page.id}", value: '<p>New content.</p>' }
    assert_response :success
    assert_equal '<p>New content.</p>', page.reload.content
    assert_equal '<p>New content.</p>', response.body
  end

  test 'a privileged user can edit a page title' do
    sign_in users(:executive)
    page = pages(:cluba_trail_guide)
    post '/pages/edit', params: { id: "page-resource-title-#{page.id}", name: 'New Title' }
    assert_response :success
    assert_equal 'New Title', page.reload.name
  end

  test 'an unprivileged user cannot edit a page' do
    sign_in users(:member)
    page = pages(:cluba_trail_guide)
    original_content = page.content
    post '/pages/edit', params: { id: "page-resource-#{page.id}", value: 'hacked' }
    assert_response :redirect
    assert_equal original_content, page.reload.content
  end

  test 'a privileged user can add and delete a resources page' do
    sign_in users(:executive)
    assert_difference -> { clubs(:cluba).pages.count }, 1 do
      post '/pages/add', params: { page: { name: 'New Page', content: '<p>Hello.</p>' } }
    end
    assert_redirected_to '/pages/resources'
    page = clubs(:cluba).pages.find_by(name: 'New Page')
    assert_equal 'Resources', page.section

    assert_difference -> { clubs(:cluba).pages.count }, -1 do
      post "/pages/delete/#{page.id}"
    end
    assert_redirected_to '/pages/resources'
  end

  test 'an unprivileged user cannot add a page' do
    sign_in users(:member)
    assert_no_difference -> { Page.count } do
      post '/pages/add', params: { page: { name: 'New Page', content: '<p>Hello.</p>' } }
    end
    assert_response :redirect
  end
end
