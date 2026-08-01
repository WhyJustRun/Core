require 'test_helper'

class ClubsiteTenancyTest < ActionDispatch::IntegrationTest
  test "club domain serves the club's site with its default layout" do
    host! 'cluba.test'
    get '/'
    assert_response :success
    assert_select 'header h1', text: 'Club A Orienteering'
    assert_select 'nav.navbar-colored'
    assert_select 'meta[name="wjr.clubsite.club.id"][content=?]', clubs(:cluba).id.to_s
  end

  test "club with the other layout gets the other navbar and footer" do
    host! 'clubb.test'
    get '/'
    assert_response :success
    assert_select 'nav.navbar-inverse'
    assert_select 'footer.other-footer'
  end

  test "redirect_domain 301s to the club domain preserving the path" do
    host! 'old.clubb.test'
    get '/events/view/5?foo=bar'
    assert_redirected_to 'https://clubb.test/events/view/5?foo=bar'
    assert_response :moved_permanently
  end

  test "unknown domains get a 404" do
    host! 'unknown.test'
    get '/'
    assert_response :not_found
  end

  test "club domains do not fall through to apex routes" do
    host! 'cluba.test'
    get '/users/sign_in'
    assert_response :not_found
  end

  test "apex routes still work on the apex host" do
    host! Settings.host
    get '/'
    assert_response :success
  end

  test "shared API routes work on club domains" do
    host! 'cluba.test'
    get "/iof/3.0/clubs/#{clubs(:cluba).id}/event_list.xml"
    assert_response :success
  end

  test "shared API routes work on the apex host" do
    host! Settings.host
    get "/iof/3.0/clubs/#{clubs(:cluba).id}/event_list.xml"
    assert_response :success
  end
end
