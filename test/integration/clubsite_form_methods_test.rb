require 'test_helper'

# Browsers submit form_with(model:) for persisted records as PATCH via the
# _method override; the legacy-shaped edit routes must accept it as well as
# POST.
class ClubsiteFormMethodsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
    sign_in users(:admin)
  end

  test "map edit form submits via PATCH" do
    patch "/maps/edit/#{maps(:cluba_forest).id}", params: { map: { name: 'Renamed Map' } }
    assert_response :redirect
    assert_equal 'Renamed Map', maps(:cluba_forest).reload.name
  end

  test "club edit form submits via PATCH" do
    patch '/clubs/edit', params: { club: { name: 'Renamed Club' } }
    assert_response :redirect
    assert_equal 'Renamed Club', clubs(:cluba).reload.name
  end

  test "series edit form submits via PATCH" do
    patch "/series/edit/#{series(:cluba_wednesday).id}", params: { series: { name: 'Renamed Series' } }
    assert_response :redirect
    assert_equal 'Renamed Series', series(:cluba_wednesday).reload.name
  end

  test "role edit form submits via PATCH" do
    patch "/roles/edit/#{roles(:organizer).id}", params: { role: { name: 'Renamed Role' } }
    assert_response :redirect
    assert_equal 'Renamed Role', roles(:organizer).reload.name
  end

  test "map standard edit form submits via PATCH" do
    map_standard = MapStandard.create!(name: 'Standard')
    patch "/mapStandards/edit/#{map_standard.id}", params: { map_standard: { name: 'Renamed Standard' } }
    assert_response :redirect
    assert_equal 'Renamed Standard', map_standard.reload.name
  end

  test "membership edit form submits via PATCH" do
    membership = memberships(:cluba_member_current)
    patch "/memberships/edit/#{membership.id}", params: { membership: { year: 2031 } }
    assert_response :redirect
    assert_equal 2031, membership.reload.year
  end

  test "event edit form submits via PATCH" do
    event = events(:cluba_training)
    patch "/events/edit/#{event.id}", params: { event: { name: 'Renamed Event' } }
    assert_response :redirect
    assert_equal 'Renamed Event', event.reload.name
  end
end
