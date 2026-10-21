require 'test_helper'

class RedactorPolicyTest < ActiveSupport::TestCase
  test "users without privileges cannot store files" do
    assert_not RedactorPolicy.new(users(:member)).store_file?
  end

  test "privileged users can store files" do
    assert RedactorPolicy.new(users(:executive)).store_file?
  end

  test "event organizers can store files" do
    assert RedactorPolicy.new(users(:organizer)).store_file?
  end
end
