require 'test_helper'

class UserDeletionTest < ActiveSupport::TestCase
  setup { @user = users(:member) }

  test "results are kept and re-pointed at the deleted placeholder" do
    result = results(:member_long)
    result.update!(registrant_comment: 'my personal note', official_comment: 'official note')

    Tools::UserDeletion.delete(@user)

    placeholder = User.deleted_placeholder
    result.reload
    assert_equal placeholder.id, result.user_id
    assert_nil result.registrant_comment
    assert_equal 'official note', result.official_comment
    assert_equal 3600, result.time_seconds
  end

  test "results the user registered for others point at the placeholder" do
    results(:organizer_long).update!(registrant_comment: 'registered by Mary')
    Tools::UserDeletion.delete(@user)
    assert_equal User.deleted_placeholder.id, results(:organizer_long).reload.registrant_id
    assert_nil results(:organizer_long).registrant_comment
  end

  test "the placeholder cannot be merged in either direction or selected in autocomplete" do
    placeholder = User.deleted_placeholder
    assert_raises(ArgumentError) { Tools::UserMerge.merge(@user, placeholder) }
    assert_raises(ArgumentError) { Tools::UserMerge.merge(placeholder, @user) }
    assert_not_includes User.search_by_name('deleted'), placeholder
    assert User.exists?(@user.id)
  end

  test "uploaded result lists keep their data but lose the uploader reference" do
    upload = ResultList.create!(event: events(:cluba_race), user: @user, status: 'live', data: '<ResultList/>')
    Tools::UserDeletion.delete(@user)
    assert_nil upload.reload.user_id
    assert_equal '<ResultList/>', upload.data
  end

  test "memberships, roles and privileges are removed with the account" do
    Privilege.create!(user: @user, user_group: groups(:cluba_executive))
    Tools::UserDeletion.delete(@user)

    assert_not User.exists?(@user.id)
    assert_not Membership.exists?(user_id: @user.id)
    assert_not Official.exists?(user_id: @user.id)
    assert_not Privilege.exists?(user_id: @user.id)
  end

  test "returns a summary of what was affected" do
    summary = Tools::UserDeletion.delete(@user)
    assert_equal 1, summary[:results]
    assert_operator summary[:memberships], :>=, 1
  end

  test "other users' data is untouched" do
    Tools::UserDeletion.delete(@user)
    assert_equal users(:organizer).id, results(:organizer_long).reload.user_id
  end

  test "the placeholder is reused, cannot sign in, and is not a real user" do
    first = User.deleted_placeholder
    assert_equal first, User.deleted_placeholder
    assert first.deleted_placeholder?
    assert_nil first.email
    assert first.access_locked?
    assert_not_includes User.find_all_real, first
  end

  test "the placeholder itself cannot be deleted" do
    assert_raises(ArgumentError) { Tools::UserDeletion.delete(User.deleted_placeholder) }
  end

  test "nothing is changed when the deletion fails part way" do
    result = results(:member_long)
    result.update!(registrant_comment: 'keep me')
    # Fail on the last step, after the results were already re-pointed.
    @user.define_singleton_method(:destroy!) { raise ActiveRecord::RecordNotDestroyed, 'boom' }

    assert_raises(ActiveRecord::RecordNotDestroyed) { Tools::UserDeletion.delete(@user) }

    result.reload
    assert_equal @user.id, result.user_id
    assert_equal 'keep me', result.registrant_comment
    assert Membership.exists?(user_id: @user.id)
  end
end
