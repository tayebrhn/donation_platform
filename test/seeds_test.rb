require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds create the demo projects idempotently" do
    seed_file = Rails.root.join("db", "seeds.rb")

    assert_no_difference("Project.count") { load seed_file }
    assert_no_difference("Project.count") { load seed_file }
    assert_equal "active", Project.find_by!(title: "Build a School Library").status
    assert_equal "draft", Project.find_by!(title: "Create a Community Garden").status
  end
end
