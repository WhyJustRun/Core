require 'test_helper'

class AdminDashboardTest < ActionDispatch::IntegrationTest
  setup { host! Settings.host }

  def sign_in_as(user)
    user.update!(password: 'password123', password_confirmation: 'password123')
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
  end

  test "signed-out visitors are sent to sign in" do
    get '/admin'
    assert_redirected_to '/users/sign_in'
  end

  test "club admins who are not global admins get a 404" do
    sign_in_as users(:admin)
    get '/admin'
    assert_response :not_found
    get "/admin/users/#{users(:member).id}"
    assert_response :not_found
  end

  test "lower-level global privileges cannot access account deletion" do
    group = Group.create!(name: 'Global Executive', access_level: 80)
    Privilege.create!(user: users(:member), user_group: group)
    sign_in_as users(:member)
    get '/admin'
    assert_response :not_found
    delete "/admin/users/#{users(:organizer).id}", params: { confirm: users(:organizer).id.to_s }
    assert_response :not_found
    assert User.exists?(users(:organizer).id)
  end

  test "club domains do not serve the admin dashboard" do
    sign_in_as users(:global_admin)
    host! 'cluba.test'
    get '/admin'
    assert_response :not_found
  end

  test "malformed legacy paths fall through to the normal not found response" do
    host! 'cluba.test'
    get '/Events/view/%3CA%20href='
    assert_response :not_found
    assert_not response.headers['Location']
  end

  test "global admins can search users by name, email and id" do
    sign_in_as users(:global_admin)

    get '/admin', params: { q: 'Mary' }
    assert_response :success
    assert_select 'td', text: 'member@example.com'

    get '/admin', params: { q: 'organizer@example' }
    assert_select 'td', text: 'Oscar Organizer'

    get '/admin', params: { q: users(:member).id.to_s }
    assert_select 'td', text: 'Mary Member'
  end

  test "the placeholder never shows up in search" do
    sign_in_as users(:global_admin)
    User.deleted_placeholder
    get '/admin', params: { q: 'deleted' }
    assert_response :success
    assert_select 'table', count: 0
  end

  test "the review page summarises what will be deleted" do
    sign_in_as users(:global_admin)
    get "/admin/users/#{users(:member).id}"
    assert_response :success
    assert_select 'h1', /Mary Member/
    assert_select 'input[name=confirm]'
  end

  test "deleting requires typing the user id" do
    sign_in_as users(:global_admin)
    member = users(:member)

    delete "/admin/users/#{member.id}", params: { confirm: 'nope' }
    assert_redirected_to "/admin/users/#{member.id}"
    assert User.exists?(member.id)
  end

  test "deleting with confirmation removes the account and keeps results" do
    sign_in_as users(:global_admin)
    member = users(:member)

    delete "/admin/users/#{member.id}", params: { confirm: member.id.to_s }
    assert_redirected_to '/admin'
    follow_redirect!
    assert_match(/Deleted user ##{member.id}/, response.body)

    assert_not User.exists?(member.id)
    assert_equal User.deleted_placeholder.id, results(:member_long).reload.user_id
  end

  test "admins cannot delete themselves or other global admins" do
    admin = users(:global_admin)
    sign_in_as admin

    delete "/admin/users/#{admin.id}", params: { confirm: admin.id.to_s }
    assert User.exists?(admin.id)

    other = users(:member)
    Privilege.create!(user: other, user_group: groups(:global_administrator))
    delete "/admin/users/#{other.id}", params: { confirm: other.id.to_s }
    assert User.exists?(other.id)
  end

  test "non-admins cannot delete anyone" do
    sign_in_as users(:admin)
    delete "/admin/users/#{users(:member).id}", params: { confirm: users(:member).id.to_s }
    assert_response :not_found
    assert User.exists?(users(:member).id)
  end

  test "the deleted placeholder has no public profile and cannot be reviewed" do
    placeholder = User.deleted_placeholder
    get "/users/#{placeholder.id}"
    assert_redirected_to '/'

    sign_in_as users(:global_admin)
    get "/admin/users/#{placeholder.id}"
    assert_response :not_found
  end

  test "the admin link appears only for global admins" do
    sign_in_as users(:admin)
    get '/'
    assert_select 'a[href=?]', '/admin', count: 0

    delete '/users/sign_out'
    sign_in_as users(:global_admin)
    get '/'
    assert_select 'a[href=?]', '/admin'
  end
end
