require 'test_helper'
require 'rake'

class AdminBootstrapTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('admin:grant_global_admin')
    @task = Rake::Task['admin:grant_global_admin']
  end

  test 'bootstrapping creates a global group and is safe to repeat' do
    Privilege.where(group_id: Group.where(club_id: nil).select(:id)).delete_all
    Group.where(club_id: nil).delete_all
    user = users(:member)

    assert_difference -> { Group.where(club_id: nil, access_level: 100).count }, 1 do
      assert_difference -> { Privilege.where(user_id: user.id).count }, 1 do
        capture_io { @task.reenable; @task.invoke(user.id) }
      end
    end
    assert user.has_global_privilege?(100)

    assert_no_difference -> { Privilege.count } do
      capture_io { @task.reenable; @task.invoke(user.id) }
    end
  end

  test 'bootstrapping rejects accounts without sign-in credentials' do
    user = User.create_fake('No account')
    assert_no_difference -> { Privilege.count } do
      capture_io do
        assert_raises(SystemExit) { @task.reenable; @task.invoke(user.id) }
      end
    end
  end
end
