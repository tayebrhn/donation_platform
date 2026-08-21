require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "defaults to the donor role" do
    user = User.new(name: "Taylor Reed", email: "taylor@example.com", password: "password123")

    assert_predicate user, :valid?
    assert_predicate user, :donor?
  end

  test "supports the initial roles" do
    assert_predicate users(:donor), :donor?
    assert_predicate users(:project_manager), :project_manager?
    assert_predicate users(:admin), :admin?
  end

  test "rejects an unsupported role" do
    user = User.new(name: "Taylor Reed", email: "taylor@example.com", password: "password123", role: "auditor")

    assert_predicate user, :invalid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "requires a name and valid email" do
    user = User.new(name: nil, email: "invalid", password: "password123")

    assert_predicate user, :invalid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:email], "is invalid"
  end

  test "normalizes email before validation" do
    user = User.create!(name: "Taylor Reed", email: "  TAYLOR@EXAMPLE.COM ", password: "password123")

    assert_equal "taylor@example.com", user.email
  end

  test "requires email addresses to be unique regardless of case" do
    existing_user = users(:donor)
    user = User.new(name: "Another Donor", email: existing_user.email.upcase, password: "password123")

    assert_predicate user, :invalid?
    assert_includes user.errors[:email], "has already been taken"
  end
end
