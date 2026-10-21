require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "privilege_level returns the highest access level for the club" do
    assert_equal 100, users(:admin).privilege_level(clubs(:cluba))
    assert_equal 90, users(:webmaster).privilege_level(clubs(:cluba))
    assert_equal 80, users(:executive).privilege_level(clubs(:cluba))
  end

  test "privilege_level is zero without any privileges" do
    assert_equal 0, users(:member).privilege_level(clubs(:cluba))
  end

  test "privilege_level is scoped to the club" do
    assert_equal 0, users(:admin).privilege_level(clubs(:clubb))
  end

  test "privilege_level includes global groups for any club" do
    assert_equal 100, users(:global_admin).privilege_level(clubs(:cluba))
    assert_equal 100, users(:global_admin).privilege_level(clubs(:clubb))
  end

  test "has_privilege? compares against the threshold" do
    assert users(:webmaster).has_privilege?(90, clubs(:cluba))
    assert users(:webmaster).has_privilege?(80, clubs(:cluba))
    assert_not users(:webmaster).has_privilege?(100, clubs(:cluba))
  end

  test "max_privilege_level only counts the user's own privileges" do
    assert_equal 0, users(:member).max_privilege_level
    assert_equal 100, users(:admin).max_privilege_level
    assert_not users(:member).has_privilege?(80, nil)
  end

  test "being an organizer grants no privilege level" do
    assert_equal 0, users(:organizer).privilege_level(clubs(:cluba))
  end
end
