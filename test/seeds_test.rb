require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds create the demo projects idempotently" do
    seed_file = Rails.root.join("db", "seeds.rb")

    assert_no_difference("Project.count") { load seed_file }
    assert_no_difference("Project.count") { load seed_file }
    assert_equal "active", Project.find_by!(title: "Build a School Library").status
    assert_equal "draft", Project.find_by!(title: "Create a Community Garden").status
  end

  test "seeds bootstrap an administrator from environment variables" do
    environment = {
      "ADMIN_NAME" => "First Administrator",
      "ADMIN_EMAIL" => "first.admin@example.com",
      "ADMIN_PASSWORD" => "secure-password-123"
    }
    original_environment = environment.keys.to_h { |key| [ key, ENV[key] ] }

    environment.each { |key, value| ENV[key] = value }
    assert_difference("User.admin.count", 1) { load Rails.root.join("db", "seeds.rb") }

    admin = User.find_by!(email: environment["ADMIN_EMAIL"])
    assert_equal "First Administrator", admin.name
    assert admin.valid_password?(environment["ADMIN_PASSWORD"])
  ensure
    original_environment.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
