require 'test_helper'

class ClubTest < ActiveSupport::TestCase
  test "clubsite_url builds a URL from the club's domain" do
    assert_equal 'https://cluba.test/events/view/1', clubs(:cluba).clubsite_url('/events/view/1')
  end

  test "visible scope excludes hidden clubs" do
    assert_includes Club.visible, clubs(:cluba)
    assert_not_includes Club.visible, clubs(:federation)
  end
end
